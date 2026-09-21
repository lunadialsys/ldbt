local task = require 'lib.task'
local meta = require 'lib.meta'
local util = require 'impl.util'
local lfs = require 'lfs'
local printer = require 'impl.printer'

local record build_task is task.Task
    record BuildResult
        success: boolean
        failure_point: string
        errors: integer
        warnings: integer
    end

    run: function(meta.PackageInfo, boolean): BuildResult
end

local function recurse_srcdir(path: string, start?: string): {{string, string}}, {string}
    local results = {}
    local dirs = {}

    for item in lfs.dir(path) do
        -- skip over . or ..
        if item == '.' or item == '..' then
            goto next
        end

        local itempath = util.combine(path, item)

        local result_path: string
        if start then
            result_path = util.combine(start, item)
        else
            result_path = item
        end

        local mode = lfs.attributes(itempath, 'mode')

        if mode == 'directory' then
            table.insert(dirs, result_path)
            local r, d = recurse_srcdir(itempath, result_path)
            for _,x in ipairs(r) do
                table.insert(results, x)
            end
            for _,x in ipairs(d) do
                table.insert(dirs, x)
            end
        elseif mode == 'file' then
            local ext_from = string.find(result_path, '%.')
            local extension = string.sub(result_path, ext_from)
            local without_ext = string.sub(result_path, 1, ext_from - 1)
            -- only compile proper Teal files (not .d.tl and not .lua)
            if extension ~= '.tl' then
                goto next
            end
            table.insert(results, {result_path, without_ext})
        end

        ::next::
    end

    return results, dirs
end

local function parse_compiler_section(output: string, src_path: string, start_pattern: string): {printer.ErrorInfo}
    local errors = {}
    local error_start, errors_from = string.find(output, start_pattern)
    if error_start then
        local errors_to = string.find(output, '%-%-%-%-%-%-%-%-', errors_from)
        local all_errors = string.sub(output, errors_from+1, errors_to-1)
        local cursor = 1
        local next_newline = string.find(all_errors, '\n', cursor)
        while next_newline do
            local error_msg = string.sub(all_errors, cursor, next_newline - 1)

            local err_object: printer.ErrorInfo

            local cut_error = string.sub(error_msg, #src_path + 1)
            local iter = string.gmatch(cut_error, ':(%d+):(%d+): (.+)')
            local t_line, t_col, rest = iter()
            if t_line then
                local line = tonumber(t_line) as integer
                local column = tonumber(t_col) as integer
                err_object = {line = line, column = column, message = rest}
            else
                err_object = {message = error_msg}
            end
            table.insert(errors, err_object)

            cursor = next_newline + 1
            next_newline = string.find(all_errors, '\n', cursor)
        end
    end
    return errors
end

local function parse_compiler_output(output: string, src_path: string): boolean, {printer.ErrorInfo}, {printer.ErrorInfo}
    -- parse errors (note: not syntax errors)
    local errors = parse_compiler_section(output, src_path, '%d+ error[s]?:\n')
    local syntax = parse_compiler_section(output, src_path, '%d+ syntax error[s]?:\n')
    if #syntax > 0 then
        for _,j in ipairs(syntax) do
            table.insert(errors, j)
        end
    end
    local warnings = parse_compiler_section(output, src_path, '%d+ warning[s]?:\n')

    return #errors > 0, errors, warnings
end

function build_task.run(pkg: meta.PackageInfo, verbose: boolean): build_task.BuildResult
    if pkg.version then
        print('%{bright white}building package %{bright cyan}%s %{dim white}(version %s)', pkg.name, pkg.version)
    else
        print('%{bright white}building package %{bright cyan}%s', pkg.name)
    end

    local dir_dst = util.fix_separator(pkg.target_dir)
    lfs.mkdir(dir_dst)

    local dir_src = util.fix_separator(pkg.source_dir)
    local units, dirs = recurse_srcdir(dir_src)

    for _, dir in ipairs(dirs) do
        local dst_path = util.combine(dir_dst, dir)
        lfs.mkdir(dst_path)
    end

    local total_warnings = 0
    for _, tuple in ipairs(units) do
        local unit, no_ext = table.unpack(tuple)
        local src_path = util.combine(dir_src, unit)
        local dst_path = util.combine(dir_dst, no_ext .. '.lua')
        print('  %{dim white}%s -> %s%{reset}', src_path, dst_path)
        
        local redirection = util.stream_redirection
        local cmd = string.format([[tl gen -c --gen-target=%s --gen-compat=%s -o %s %s %s]],
            pkg.gen_target, pkg.gen_compat, dst_path, src_path, redirection)
        if verbose then
            print(cmd)
        end
        local fd = io.popen(cmd, 'r')
        fd:setvbuf('no')
        local result = fd:read('*a')
        local stop, errors, warnings = parse_compiler_output(result, src_path)
        if #warnings > 0 then
            printer.print_errors(src_path, warnings, printer.warning)
            total_warnings = total_warnings + #warnings
        end
        if stop then
            printer.print_errors(src_path, errors, printer.error)
            return {success = false, failure_point = src_path, errors = #errors, warnings = 0}
        end
    end
    return {success = true, failure_point = nil, errors = 0, warnings = total_warnings}
end

return build_task