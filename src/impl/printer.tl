require 'impl.console'

local record printer
    record ErrorInfo
        line: integer | nil
        column: integer | nil
        message: string
    end

    print_errors: function(string, {ErrorInfo}, TypePrinter)
    type TypePrinter = function(ErrorInfo, string)
end

function printer.error(err: printer.ErrorInfo, line: string)
    if line then
        local preamble = string.format('%d | ', err.line as integer)
        local total_column = err.column + #preamble
        local pointer = string.rep(' ', total_column - 1) .. '^'
        eprint('  %{dim white}%s%{reset}%s', preamble, line)
        eprint('  %{bright red}%s', pointer)
        eprint('  %{red}error %{reset}%{bright red}%d:%d: %s', err.line, err.column, err.message)
    else
        eprint('  %{red}error %{reset}%{bright red}%s', err.message)
        eprint('  %{dim white}(could not derive error\'s location)')
    end
end

function printer.warning(err: printer.ErrorInfo, line: string)
    if line then
        local preamble = string.format('%d | ', err.line as integer)
        local total_column = err.column + #preamble
        local pointer = string.rep(' ', total_column - 1) .. '^'
        eprint('  %{dim white}%s%{reset}%s', preamble, line)
        eprint('  %{bright yellow}%s', pointer)
        eprint('  %{yellow}warning %{reset}%{bright yellow}%d:%d: %s', err.line, err.column, err.message)
    else
        eprint('  %{yellow}warning %{reset}%{bright yellow}%s', err.message)
        eprint('  %{dim white}(could not derive warning\'s location)')
    end
end

function printer.print_errors(filepath: string, errors: {printer.ErrorInfo}, method: printer.TypePrinter)
    for _,err in ipairs(errors) do
        if err.line then
            -- todo this is bad
            local fd = io.open(filepath, 'r')
            local lines: {number:string} = {}
            for line in fd:lines('l') do
                table.insert(lines, line)
            end
            fd:close()

            local line = lines[err.line]
            method(err, line)
        else
            method(err, nil)
        end
    end
end

return printer