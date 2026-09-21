-- ldbt: luna dial system's build tool
-- a very small build tool for the Teal programming language

package.path = package.path .. './?.lua;'
require 'global_config'
require 'impl.console'
require 'command'

local argparse = require 'argparse'

local allcommands: {string:LdbtCommand} = {
    ["build b"] = require('commands.build')
}

local parser = argparse('ldbt', 'luna dial\'s build tool')
parser:require_command(false)
parser:add_help_command('help')
parser:option('--version'):description('Show version information and exit.'):args(0)

for key,val in pairs(allcommands) do
    local c = parser:command(key, val.description)
    val:configure(c)
    val.command = c
    c:handle_options(true)
end

local args = parser:parse()
-- handle being called with --version
if args.version then
    print(
        '%{bright cyan}ldbt v%d.%d.%d %{white}(%s)%{dim white} - Copyright (C) 2026 Luna Dial System',
        _CONFIG.version[1], _CONFIG.version[2], _CONFIG.version[3],
        _VERSION
    )
    os.exit(0)
end

local function find_command(): LdbtCommand, string
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

local function dispatch_command(cmd: LdbtCommand, cmdname: string)
    local cmd_errfunc = function(er): any
        if type(er) == 'string' then
            return debug.traceback(er)
        end
        return er
    end

    local ok, err: boolean, any | nil = xpcall(cmd.execute, cmd_errfunc, cmd, args as ArgsTable)
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
        end
    end
end

local cmd, name = find_command()
if not cmd then
    eprint('%{bright red}error%{white}: a command is required')
    eprint("(use 'help' to see available commands)")
    os.exit(1)
end
dispatch_command(cmd, name)