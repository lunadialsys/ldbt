local argparse = require 'argparse'

local record cli
    type Arguments = {string: any}

    record Command
        description: string
        command: argparse.Command
        configure: function(self, argparse.Command)
        execute: function(self, Arguments)
    end
end

return cli