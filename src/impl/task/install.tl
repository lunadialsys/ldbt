local task = require 'lib.task'
local meta = require 'lib.meta'
local util = require 'impl.util'
local config = require 'impl.config'

local record install_task is task.Task
    run: function(meta.PackageInfo, string): nil
end

local script_template_windows = [[
@echo off
setlocal
"%s" -e "package.path='%s;%s';package.cpath='%s'" "%s" %%*
exit /b %%ERRORLEVEL%%
]]

local function get_script_filename(name: string): string
    return util.is_windows and name..'.bat' or name
end

local function make_template(pkg: meta.PackageInfo, dir: string): string
    if util.is_windows then
        return string.format(script_template_windows,
        config.values.lua,
        util.escape(dir .. util.path_separator .. '?.lua'),
        util.escape(os.getenv('LUA_PATH')),
        util.escape(os.getenv('LUA_CPATH')),
        util.combine(dir, pkg.entrypoint)
        )
    else
        error('unsupported platform, oops!')
    end
end

function install_task.run(pkg: meta.PackageInfo, artifact_dir: string): nil
    local bin_path = util.combine(config.home, config.values.bin_dir, get_script_filename(pkg.name))
    local script = make_template(pkg, artifact_dir)
    local f = io.open(bin_path, 'w')
    f:write(script)
    f:close()
end

return install_task