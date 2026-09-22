local argparse = require 'argparse'

local record cli
    record Arguments
        verbose: integer
        quiet: boolean
    end

    record Command
        description: string
        command: argparse.Command
        configure: function(self, argparse.Command)
        execute: function(self, Arguments): integer
    end
end

return cli