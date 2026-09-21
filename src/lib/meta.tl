local semver = require 'semver'

local record metadata
    enum DependencySource
        -- this dep refers to the Lua interpreter
        -- special-case
        'lua'

        -- dep is from LuaRocks
        'rock'
    end

    enum VersionConstraintKind
        -- >1.2.3 (holds if installed strictly newer than arg)
        'gt'
        -- >=1.2.3 (holds if installed newer or at arg)
        'gte'

        -- ==1.2.3 (holds if installed is EXACTLY of ver. arg)
        'pin'
        
        -- <1.2.3 (holds if installed strictly older than arg)
        'lt'
        -- <=1.2.3 (holds if installed older or at arg)
        'lte'
    end

    record VersionConstraint
        kind: VersionConstraintKind
        target: semver.VersionInfo
    end

    record Dependency
        source: DependencySource
        name: string

        -- if constraints == {}, latest version
        constraints: {VersionConstraint}

        -- if true, allows dev versions (from luarocks eg)
        dev: boolean
    end

    record PackageInfo
        -- package name, required
        name: string

        -- version, defaults to nil (unversioned)
        version: string | nil

        -- metadata
        description: string | nil
        authors: {string}

        -- target lua ver. to emit, defaults to 5.1
        gen_target: string
        gen_compat: string

        -- where's the source code? defaults to src/
        source_dir: string
        -- where's the built output? defaults to dist/
        target_dir: string

        -- what does it need? defaults to {}
        dependencies: {Dependency}
    end
end

return metadata