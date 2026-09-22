-- ldbt: luna dial system's build tool
-- a very small build tool for the Teal programming language

local global_config = require 'global_config'
require 'impl.console'
local cli = require 'lib.cli'
local config = require 'impl.config'

local argparse = require 'argparse'

local allcommands: {string:cli.Command} = {
    ['build b'] = require('commands.build'),
    ['install'] = require('commands.install'),

    ['path'] = require('commands.path')
}

local parser = argparse('ldbt', 'luna dial\'s build tool')
parser:require_command(false)
parser:add_help_command('help')
parser:option('--version'):description('Show version information and exit.'):args(0)

parser:option('-v --verbose'):description('Print out additional debug info.'):args(0):count('0-2')
parser:option('-q --quiet'):description('Print out less output.'):args(0)

for key,val in pairs(allcommands) do
    local c = parser:command(key, val.description)
    if val.configure then
        val:configure(c)
    end
    val.command = c
    c:handle_options(true)
end

local args = parser:parse()
-- handle being called with --version
if args.version then
    print(
        '%{bright cyan}ldbt v%d.%d.%d %{dim white} - Copyright (C) 2026 Luna Dial System',
        global_config.version.major, global_config.version.minor, global_config.version.patch,
        _VERSION
    )
    local teal = require 'tl'
    local tlpath = package.searchpath('tl', package.path)
    print('Using %s (teal %s at %s)', _VERSION, teal.version(), tlpath)
    os.exit(0)
end

local function find_command(): cli.Command, string
    for key,val in pairs(allcommands) do
        for alias in key:gmatch("(%w+)%s*") do
            if args[alias] then
                return val, alias
            end
        end
    end
    return nil
end

local record UserError
    msg: string
    data: any | nil
end

local function dispatch_command(cmd: cli.Command, cmdname: string)
    local exitcode = 0
    local _inner_dispatch = function(c: cli.Command, a: cli.Arguments)
        config.ensure()
        exitcode = c:execute(a)
    end

    local cmd_errfunc = function(er): any
        if type(er) == 'string' then
            return debug.traceback(er)
        end
        return er
    end

    local ok, err: boolean, any | nil = xpcall(_inner_dispatch, cmd_errfunc, cmd, args as cli.Arguments)
    if not ok then
        if type(err) == 'table' then
            local er = err as UserError
            eprint('%{bright red}error%{white}: %s', er.msg)
            if er.data then
                eprint(tostring(er.data))
            end
            os.exit(1)
        else
            eprint('%{bright red}internal error in command %s', cmdname)
            eprint('%{dim white}-------------')
            eprint(tostring(err))
            eprint('%{dim white}-------------')
            eprint('%{dim white}please report a bug!')
            os.exit(1)
        end
    end
    os.exit(exitcode)
end

local cmd, name = find_command()
if not cmd then
    eprint('%{bright red}error%{white}: a command is required')
    eprint("(use 'help' to see available commands)")
    os.exit(1)
end
dispatch_command(cmd, name)