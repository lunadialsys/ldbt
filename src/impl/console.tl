local _done = false
if not _done then
    -- kinda bad, but we need to hook os.getenv here to get ansicolors
    -- to output colour codes on Windows systems. it makes an assumption
    -- that *no* Windows consoles support ANSI colour codes, which hasn't
    -- been true in something like 10 years (ever since windows terminal).
    local disable_colours = os.getenv('LDBT_NO_COLOR') ~= nil
    local _real_getenv = os.getenv
    os.getenv = function(n: string): string
        if n == 'ANSICON' then
            return disable_colours and nil or '1'
        end
        return _real_getenv(n)
    end
    global colors = require 'ansicolors'
    os.getenv = _real_getenv
    _done = true
end

local _real_print = print
_G['print'] = function(s: string, ...)
    _real_print(string.format(colors(s), ...))
end

global function eprint(s: string, ...)
    io.stderr:write(string.format(colors(s)..'\n', ...))
end
