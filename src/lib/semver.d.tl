-- type definitions for semver.lua
-- https://github.com/kikito/semver.lua

local record semver
    record VersionInfo
        major: integer
        minor: integer
        patch: integer
        prerelease: string | nil
        build: string | nil

        nextMajor: function(self): VersionInfo
        nextMinor: function(self): VersionInfo
        nextPatch: function(self): VersionInfo

        metamethod __eq: function(lhs: VersionInfo, rhs: VersionInfo): boolean
        metamethod __lt: function(lhs: VersionInfo, rhs: VersionInfo): boolean
        metamethod __le: function(lhs: VersionInfo, rhs: VersionInfo): boolean
        metamethod __pow: function(lhs: VersionInfo, rhs: VersionInfo): boolean
    end

    metamethod __call: function(any...): VersionInfo
end

return semver