--- @module version
-- Describes the current version of Modules

local version = require(script.Parent)

local versionTests = {}

versionTests["test_version"] = function ()
	assert(version.MAJOR >= 0)
	assert(version.MINOR >= 0)
	assert(version.PATCH >= 0)
end

return versionTests
