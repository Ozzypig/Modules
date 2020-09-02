--- @module version.test
-- Tests for version module

local VERSION = {
	SOFTWARE_NAME = "Modules";
	MAJOR = 1;
	MINOR = 1;
	PATCH = 1;
	PRERELEASE = {};
	BUILD_METADATA = script:FindFirstChild("build-meta")
	             and require(script["build-meta"]) or {};
}

local function toStringCopy(t)
	local t2 = {}
	for k, v in pairs(t) do
		t2[k] = tostring(v)
	end
	return t2
end

local function getVersionName(v)
	local PRERELEASE = toStringCopy(v.PRERELEASE)
	local BUILD_METADATA = toStringCopy(v.BUILD_METADATA)

	return ("%s %d.%d.%d%s%s"):format(
		v.SOFTWARE_NAME, v.MAJOR, v.MINOR, v.PATCH,
		#PRERELEASE > 0     and "-" .. table.concat(PRERELEASE, ".")     or "",
		#BUILD_METADATA > 0 and "+" .. table.concat(BUILD_METADATA, ".") or ""
	)
end

VERSION.NAME = getVersionName(VERSION)

return VERSION
