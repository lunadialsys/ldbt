local util = require 'impl.util'

local record sandbox
    members: {string:any}
end

-- exclusion: all other functions inside 'os' are wildly dangerous
local safe_os = {
    clock = os.clock,
    date = os.date,
    difftime = os.difftime,
    time = os.time
}

-- exclusion: math.randomseed modifies internal interpreter state
local safe_math = util.shallow_copy(math as table)
safe_math['randomseed'] = nil

sandbox.members = {
    -- inclusions: basic library (found within _G)
    _VERSION = _VERSION,
    print = print,
    assert = assert,
    error = error,
    setmetatable = setmetatable,
    getmetatable = getmetatable,
    ipairs = ipairs,
    pairs = pairs,
    rawget = rawget,
    rawset = rawset,
    rawequal = rawequal,
    rawlen = rawlen,
    select = select,
    next = next,
    tonumber = tonumber,
    tostring = tostring,
    type = type,
    pcall = pcall,
    xpcall = xpcall,

    -- inclusions: safe system libraries.
    -- these libraries can't modify external data or reach the outside world.
    os = safe_os,
    math = safe_math,
    string = string,
    table = table,

    -- exclusions: potentially dangerous, these functions load code dynamically.
    -- of course, the code will run in the sandbox, but there's very narrow use case for them in here,
    -- so better safe than sorry in my opinion.
    require = nil,
    load = nil,
    loadfile = nil,
    dofile = nil,
    loadstring = nil,
    dostring = nil,
    eval = nil,

    -- exclusions: not *dangerous* per-se but there's no use case for it in here.
    coroutine = nil,

    -- exclusions: definitely dangerous, libraries that directly allow modification of the interpreter or system.
    -- these are vectors for malicious code, so we don't expose them at all to package manifests.
    io = nil,
    debug = nil,
    package = nil,
}

local SANDBOX_TIMEOUT = 50.0
local SANDBOX_HOOK_INTERVAL = 10000

function sandbox.execute(chunktext: string, additional_env: table, timeout_msg: string, filename: string): any
    local env = util.shallow_copy(sandbox.members)
    for k,v in pairs(additional_env as {string:any}) do
        env[k] = v
    end
    
    local chunk, load_err = load(chunktext, '@'..filename, 't', env as {string:any})
    if chunk == nil then
        error({msg = 'error while parsing', data = load_err})
    end
    
    local start = os.clock()
    local deadline = start + (SANDBOX_TIMEOUT / 1000.0)

    local TOOK_TOO_LONG = {msg = timeout_msg}
    setmetatable(TOOK_TOO_LONG as table, {__ldbt_internal = true} as metatable<table>)

    local function evaluator_hook()
        local now = os.clock()
        if now > deadline then
            error(TOOK_TOO_LONG)
        end
    end

    debug.sethook(evaluator_hook, '', SANDBOX_HOOK_INTERVAL)
    -- TODO proper separation between config and sandbox via debug.setupvalue
    local ok, err = pcall(chunk)
    debug.sethook(nil, nil)

    if not ok then
        local errmeta = getmetatable(err) as {string:any}
        if errmeta ~= nil and errmeta.__ldbt_internal then
            error(err) -- directly rethrow an internal error
            return
        end
        error({msg = 'error while evaluating', data = err})
    end
    return err
end

return sandbox