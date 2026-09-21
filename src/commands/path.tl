local util = require 'impl.util'
local config = require 'impl.config'
local cli = require 'lib.cli'

local cmd: cli.Command = {}
cmd.description = 'Print out environments for your ldbt configuration.'

function cmd:execute(_args: cli.Arguments): integer
    local bindir = util.combine(config.home, config.values.bin_dir)
    if util.is_windows then
        print('On Windows, add the following to your user Path environment variable:')
        print(bindir)
    else
        local path = os.getenv('PATH')
        print('export PATH="%s;%s"', path, bindir)
    end
    return 0
end

return cmd