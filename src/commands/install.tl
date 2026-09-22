local cli = require 'lib.cli'
local argparse = require 'argparse'
local libpkg = require 'impl.package'
local build_task = require 'impl.task.build'
local install_task = require 'impl.task.install'
local util = require 'impl.util'
local config = require 'impl.config'
local lfs = require 'lfs'
local printer = require 'impl.printer'

local cmd: cli.Command = {}
cmd.description = 'Compile and install a project.'

function cmd:configure(_c: argparse.Command) end

function cmd:execute(args: cli.Arguments): integer
    local _args = args
    local pkg = libpkg.evaluate_manifest()

    if pkg.version then
        print('%{bright white}installing package %{bright cyan}%s %{dim white}(version %s)', pkg.name, pkg.version)
    else
        print('%{bright white}installing package %{bright cyan}%s', pkg.name)
    end

    local pkg_id = pkg.version and string.format('%s@%s', pkg.name, pkg.version) or pkg.name
    local install_dir = util.combine(config.home, config.values.install_dir, pkg_id)
    lfs.mkdir(install_dir)

    local build_res = build_task.run(pkg, {
        file_tracer = args.verbose >= 1 and printer.trace_file,
        verbose = args.verbose >= 2
    }, install_dir)

    if not build_res.success then
        eprint('%{bright red}install failed due to %d error%s', build_res.errors, build_res.errors > 1 and 's' or '')
        return 1
    end
    if build_res.warnings > 0 then
        print('%{bright yellow}%d warning%s', build_res.warnings, build_res.warnings > 1 and 's' or '')
    end
    install_task.run(pkg, install_dir)
    print('%{bright green}package installed')
    return 0
end

return cmd