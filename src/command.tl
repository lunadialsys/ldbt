local argparse = require 'argparse'

global type ArgsTable = {string: any}

global interface LdbtCommand
    description: string
    command: argparse.Command
    configure: function(self, argparse.Command)
    execute: function(self, ArgsTable)
end