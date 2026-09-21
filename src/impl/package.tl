local dsl = require 'impl.dsl'
local meta = require 'lib.meta'
local sandbox = require 'impl.sandbox.sandbox'

local lib_package = {}

local PACKAGE_MANIFEST_FILENAME = 'ldbt.lua'
local timeout_exceeded = 'manifest evaluation took too long (is your script too complex?)'

function lib_package.evaluate_manifest(): meta.PackageInfo
    -- TODO: add support for building packages in different locations than the cwd
    local fd = io.open(PACKAGE_MANIFEST_FILENAME, 'r')
    if fd == nil then
        error({msg = 'cannot open ldbt.lua; is this a ldbt project?'})
    end
    local src = fd:read('*a')
    fd:close()

    dsl.start_eval()
    -- run it with the methods from the dsl's global table available
    sandbox.execute(src, dsl.global, timeout_exceeded, 'ldbt.lua')
    local p = dsl.get()
    return p
end

return lib_package