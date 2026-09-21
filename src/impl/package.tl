local util = require 'impl.util'
local dsl = require 'impl.dsl'
local meta = require 'impl.meta'

local lib_package = {}

-- members available within package scripts

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

local package_sandbox: {string:any} = {
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

-- add the DSL methods into the package's sandbox
for k,v in pairs(dsl.global as {string:any}) do
    package_sandbox[k] = v
end

local PACKAGE_MANIFEST_FILENAME = 'ldbt.lua'

local PACKAGE_SCRIPT_TIMEOUT = 50.0
local PACKAGE_SCRIPT_HOOK_INTERVAL = 10000
local TOOK_TOO_LONG = {
    msg = 'manifest evaluation took too long (is your script too complex?)',
}
setmetatable(TOOK_TOO_LONG as table, {__ldbt_internal = true} as metatable<table>)

function lib_package.evaluate_manifest(): meta.PackageInfo
    -- TODO: add support for building packages in different locations than the cwd
    local fd = io.open(PACKAGE_MANIFEST_FILENAME, 'r')
    if fd == nil then
        error({msg = 'cannot open ldbt.lua; is this a ldbt project?'})
    end
    local chunktext = fd:read('*a')
    local chunk, load_err = load(chunktext, '@'..PACKAGE_MANIFEST_FILENAME, 't', package_sandbox as {string:any})
    if chunk == nil then
        error({msg = 'error while parsing manifest', data = load_err})
    end
    
    local start = os.clock()
    local deadline = start + (PACKAGE_SCRIPT_TIMEOUT / 1000.0)

    local function evaluator_hook()
        local now = os.clock()
        if now > deadline then
            error(TOOK_TOO_LONG)
        end
    end

    dsl.start_eval()
    debug.sethook(evaluator_hook, '', PACKAGE_SCRIPT_HOOK_INTERVAL)
    local ok, err = pcall(chunk)
    debug.sethook(nil, nil)

    if not ok then
        local errmeta = getmetatable(err) as {string:any}
        if errmeta ~= nil and errmeta.__ldbt_internal then
            error(err) -- directly rethrow an internal error
            return
        end
        error({msg = 'error while evaluating manifest', data = err})
    end

    local p = dsl.get()
    return p
end

return lib_package