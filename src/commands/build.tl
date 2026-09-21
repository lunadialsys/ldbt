local cli = require 'lib.cli'
local argparse = require 'argparse'
local libpkg = require 'impl.package'
local build_task = require 'impl.task.build'

local cmd: cli.Command = {}
cmd.description = 'Compile a project.'

function cmd:configure(c: argparse.Command)
    c:option('-v --verbose'):args(0)
end

function cmd:execute(args: cli.Arguments)
    local _args = args
    local pkg = libpkg.evaluate_manifest()
    local res = build_task.run(pkg, args.verbose == true)
    if not res.success then
        eprint('')
        eprint('%{bright red}build failed due to %d error%s', res.errors, res.errors > 1 and 's' or '')
    else
        print('')
        if res.warnings > 0 then
            print('%{bright yellow}build successful with %d warning%s', res.warnings, res.warnings > 1 and 's' or '')
        else
            print('%{bright green}build successful')
        end
    end
end

return cmd