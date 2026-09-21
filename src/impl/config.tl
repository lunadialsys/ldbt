local util = require 'impl.util'
local lfs = require 'lfs'
local sandbox = require 'impl.sandbox.sandbox'

local record config
    record Config
        -- path to where installed binary wrappers go
        bin_dir: string
        -- path to where installed application packages go
        install_dir: string
        -- invocation to summon the Lua interpreter (eg just `lua` if the interpreter is in PATH)
        lua: string
    end
    
    home: string
    values: Config
    ensure: function()
end

local defaults = {
    lua = 'lua',
    bin_dir = util.fix_separator('bin/'),
    install_dir = util.fix_separator('install/')
}

local no_home_env = {msg='home environment not found', data='(set LDBT_HOME in your environment)'}
local function ensure_home()
    -- TODO: how do you get this on windows?
    local home_path = util.fix_separator(os.getenv('HOME') or os.getenv('LDBT_HOME') or error(no_home_env))
    if not util.is_a(home_path, 'directory') then
        error({msg='user home directory does not exist?'})
    end
    local config_path = util.combine(home_path, '.ldbt')
    config.home = config_path
    lfs.mkdir(config_path)
end

local function evaluate()
    local cfg_file = util.combine(config.home, 'config.lua')
    if not util.is_a(cfg_file, 'file') then
        config.values = defaults
        return
    end
    local fd = io.open(cfg_file, 'r')
    local src = fd:read('*a')
    fd:close()
    local w = sandbox.execute(src, {}, 'config took too long to evaluate', '@config.lua') as {string:any}
    if type(w) ~= 'table' then
        config.values = defaults
        return
    end
    config.values = {}
    for k,v in pairs(defaults as {string:any}) do
        (config.values as {string:any})[k] = w[k] or v
    end
end

local function make_dirs()
    lfs.mkdir(util.combine(config.home, config.values.bin_dir))
    lfs.mkdir(util.combine(config.home, config.values.install_dir))
end

function config.ensure()
    ensure_home()
    evaluate()
    make_dirs()
end

return config