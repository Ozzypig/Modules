--- @module version
-- Describes the current version of Modules

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local version = require(Modules:WaitForChild("version"))

local versionTests = {}

versionTests["test_version"] = function ()
	assert(version.MAJOR >= 0, "version.MAJOR should be positive")
	assert(version.MINOR >= 0, "version.MINOR should be positive")
	assert(version.PATCH >= 0, "version.PATCH should be positive")
end

return versionTests
