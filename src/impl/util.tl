local lfs = require 'lfs'

local lib_util = {
    path_separator: string = nil,
    is_windows: boolean = false,
    stream_redirection: string = nil,
}

function lib_util.shallow_copy(t: {any:any}): {any:any}
    local new_table = {}
    for k,v in pairs(t) do
        new_table[k] = v
    end
    return new_table
end

function lib_util.split(s: string, ptn: string): {string}
    local results = {}
    local pos = 1
    local from, to: integer, integer
    repeat
        from, to = string.find(s, ptn, pos)
        local v = string.sub(s, pos, from and from - 1 or nil)
        table.insert(results, v)
        if from then
            pos = from + (to - from) + 1
        end
    until not from
    return results
end

lib_util.is_windows = package.config:sub(1,1) == '\\'
lib_util.path_separator = package.config:sub(1,1)
lib_util.stream_redirection = '2>&1'

function lib_util.combine(...: string): string
    return table.concat(table.pack(...), lib_util.path_separator)
end

function lib_util.fix_separator(s: string): string
    -- if on windows, replace forward slashes with backslashes because that's probably what you want
    if lib_util.is_windows then
        s = string.gsub(s, '/', '\\')
    end
    -- cut off the last character if our path ends with the path separator
    if string.sub(s, #s, #s) == lib_util.path_separator then
        s = string.sub(s, 1, #s-1)
    end
    return s
end

function lib_util.is_a(path: string, mode: lfs.FileMode): boolean
    local t = lfs.attributes(path, 'mode')
    return t and t == mode
end

return lib_util