local meta = require 'impl.meta'
local util = require 'impl.util'
local semver = require 'semver'

local lib_dsl = {
    data: table = nil,
    global: {string:any} = nil
}

local env: {string:any} = {}

-- 'propagated error'
local function perror(msg: string, ...: any): table
    local er = {msg = string.format(msg, ...)} as table
    setmetatable(er, {__ldbt_internal = true} as metatable<table>)
    error(er)
end

local function unique_setter(name: string, field?: string): function(string)
    if field == nil then field = name end
    return function(n: string)
        local d = lib_dsl.data as {string:any}
        if d[field] ~= nil then
            perror('more than one "'..name..'" directive present in manifest')
        end
        (lib_dsl.data as {string:any})[field] = n
    end
end

---------------------------- basic setter directives
-- package 'name' (required)
env.package = unique_setter('package', 'name')

-- description 'text'
env.description = unique_setter('description')

-- version '0.0.1'
env.version = unique_setter('version')

-- target '5.1' && compat '5.1'
env.target = unique_setter('gen_target', 'target')
env.compat = unique_setter('gen_compat', 'compat')

-- source 'src/' && target 'dist/'
env.source = unique_setter('source', 'source_dir')
env.dist = unique_setter('dist', 'target_dir')

env.author = function(n: string)
    if lib_dsl.data.authors == nil then
        lib_dsl.data.authors = {}
    end
    table.insert(lib_dsl.data.authors as {string}, n)
end


---------------------------- dependencies & packages
local record DslDependency
    _source: meta.DependencySource
    _name: string
    _version: string | nil
    version: function(self, v:string): DslDependency
end

local function make_dep(name: string, source: meta.DependencySource): DslDependency
    local p = {
        _source = source,
        _name = name,
        _version: string | nil = nil
    }

    function p:version(v: string): DslDependency
        self._version = v
        return self
    end

    return p
end

env.lua = make_dep('lua', 'lua'):version('>=5.1') -- default

env.rock = function(n: string): DslDependency
    return make_dep(n, 'rock')
end

local function convert_constraint(dep: DslDependency, str: string,
    _existing: {meta.VersionConstraint}): meta.VersionConstraint
    local kind_idx, kind_to = string.find(str, '[<>=]+')
    if not kind_idx or kind_idx ~= 1 then
        perror('dependency %s: invalid version (bad comparison operator)', dep._name)
    end
    local ft = string.sub(str, 1, kind_to)
    local lt = string.sub(str, kind_to + 1)
    local kind: meta.VersionConstraintKind
    if ft == '==' then
        kind = 'pin'
    elseif ft == '>' then
        kind = 'gt'
    elseif ft == '>=' then
        kind = 'gte'
    elseif ft == '<' then
        kind = 'lt'
    elseif ft == '<=' then
        kind = 'lte'
    else
        perror('dependency %s: invalid version (bad comparison operator)', dep._name)
    end
    local ver = semver(lt)
    return {kind = kind, target = ver}
end

local function convert_dep(dep: DslDependency): meta.Dependency
    local newdep: meta.Dependency = {}

    newdep.source = dep._source
    newdep.name = dep._name

    if dep._version then
        local constraints: {meta.VersionConstraint} = {}
        local sp = util.split(dep._version, ',%s*')
        for _,v in ipairs(sp) do
            table.insert(constraints, convert_constraint(dep, v, constraints))
        end
        newdep.constraints = constraints
    else
        perror('dependency %s: version is missing', dep._name)
    end

    return newdep
end

env.dependencies = function(d: {{string:any}})
    local deptable = {}

    for _,k in ipairs(d) do
        deptable[k._name] = convert_dep(k as DslDependency)
    end
    
    lib_dsl.data.dependencies = deptable
end


---------------------------- library
function lib_dsl.start_eval()
    lib_dsl.data = {}
end

function lib_dsl.get(): meta.PackageInfo
    local d = lib_dsl.data

    if not d.name then
        error({msg='package directive is required'})
    end

    -- if no deps specified, just default to lua >=5.1
    local deps = d.dependencies
    if not d.dependencies then
        deps = {
            lua = convert_dep(env.lua as DslDependency)
        }
    end

    return {
        name = d.name,
        version = d.version,
        description = d.description,
        authors = d.authors or {},
        gen_target = d.gen_target or '5.1',
        gen_compat = d.gen_compat or 'optional',
        source_dir = d.source_dir or 'src/',
        target_dir = d.target_dir or 'dist/',
        dependencies = deps
    } as meta.PackageInfo
end

lib_dsl.global = env
return lib_dsl