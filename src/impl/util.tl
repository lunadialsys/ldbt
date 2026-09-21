local lfs = require 'lfs'

local record util
    path_separator: string
    is_windows: boolean
    stream_redirection: string
end

util.is_windows = package.config:sub(1,1) == '\\'
util.path_separator = package.config:sub(1,1)
util.stream_redirection = '2>&1'

function util.shallow_copy(t: table): table
    local new_table = {}
    for k,v in pairs(t) do
        new_table[k] = v
    end
    return new_table
end

function util.escape(s: string): string
    return (s
        :gsub('\\', '\\\\')
        :gsub('"', '\\"'))
end

function util.split(s: string, ptn: string): {string}
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

function util.combine(...: string): string
    return table.concat(table.pack(...), util.path_separator)
end

function util.fix_separator(s: string): string
    -- if on windows, replace forward slashes with backslashes because that's probably what you want
    if util.is_windows then
        s = string.gsub(s, '/', '\\')
    end
    -- cut off the last character if our path ends with the path separator
    if string.sub(s, #s, #s) == util.path_separator then
        s = string.sub(s, 1, #s-1)
    end
    return s
end

function util.is_a(path: string, mode: lfs.FileMode): boolean
    local t = lfs.attributes(path, 'mode')
    return t and t == mode
end

return util