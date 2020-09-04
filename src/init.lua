--- The main ModuleLoader, designed to replace the built-in require function.
-- ModuleLoader is the main object returned by the "Modules" ModuleScript. It is designed to
-- replace the built-in `require` function, retaining all its normal behaviors while also adding
-- more:
--
--   * Call with a string, eg `require("Namespace:ModuleName")`, to require a Module in a Namespace
--   * Call `require.server` to skip requires if on the client (get nil instead)
--   * Call `require.client` to skip requires if on the server (get nil instead)
--
-- @usage local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"))
-- @module ModuleLoader

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

local ModuleLoader = {}
setmetatable(ModuleLoader, ModuleLoader)

ModuleLoader.NAME_SPLIT_PATTERN = "%."
ModuleLoader.VERSION = require(script.version)
ModuleLoader.DEBUG_MODE = (function ()
	return script:FindFirstChild("DebugEnablede")
	   or (script:FindFirstChild("Debug")
	   and script.Debug:IsA("BoolValue")
	   and script.Debug.Value)
end)()

--- Starting with `parent`, call FindFirstChild using each name in the `names` array
-- until one is found
--@return Instance
local function getObject(parent, names)
	assert(typeof(parent) == "Instance")
	assert(type(names) == "table")
	local object = parent
	for _, name in ipairs(names) do
		if not object then
			return
		end

		object = object:FindFirstChild(name)
	end
	return object
end

--- Split the given string by repeatedly calling find on it using the given separator
local function split(str, sep)
	local strs = {}
	local s, e
	while true do
		s, e = string.find(str, sep)
		if s then
			table.insert(strs, string.sub(str, 1, s - 1))
			str = string.sub(str, e + 1)
		else
			break
		end
	end
	table.insert(strs, str)
	return strs
end

--- Given a string like "Module.Submodule.With%.Period.Whatever", split it on . and return a table of strings
local function splitNames(str)
	local t = split(str, ModuleLoader.NAME_SPLIT_PATTERN)
	local i = 1
	while i <= #t do
		local value = t[i]
		if string.sub(value, #value) == "%" then
			-- Trim the trailing %
			t[i] = string.sub(value, 1, #value - 1)
			-- Concatenate with the next string (if there is one)
			if i < #t then
				t[i] ..= "." .. table.remove(t, i + 1)
			end
		else
			-- Move to the next
			i = i + 1
		end
	end
	return t
end

--- Prints only if `DEBUG_MODE` is true.
-- @function ModuleLoader:_print
-- @local
function ModuleLoader:_print(...)
	if self.DEBUG_MODE then
		print(...)
	end
end

--- Finds a module given its fully-qualified name
-- @private
function ModuleLoader:_findModule(fqName: string)
	assert(type(fqName) == "string")

	-- Determine the namespace and module name - the default namespace is "Modules"
	local namespace = "Modules"
	local moduleName = fqName

	-- A colon indicates that a namespace is specified - split it if so
	local s, e = string.find(fqName, "[^%%]:")
	if s then
		namespace = string.sub(fqName, 1, s)
		moduleName = string.sub(fqName, e + 1)
	end

	local namespaceNames = splitNames(namespace)
	local moduleNames = splitNames(moduleName)

	-- Try to find what we're looking for on the client
	local namespaceClient = namespace == script.Name and script
						or getObject(ReplicatedStorage, namespaceNames)
	local moduleClient = getObject(namespaceClient, moduleNames)

	if not isServer then
		if not namespaceClient then
			error(string.format("Could not find client namespace: %s", namespace), 3)
		end

		if not moduleClient then
			error(string.format("Could not find client module: %s", fqName), 3)
		end

		return moduleClient
	elseif moduleClient then
		return moduleClient
	end

	-- Try to find what we're looking for on the server
	local moduleServer
	local namespaceServer = namespace == script.Name and script
						or getObject(ServerScriptService, namespaceNames)

	if not namespaceServer then
		error(string.format("Could not find namespace: %s", namespace), 3)
	end

	moduleServer = getObject(namespaceServer, moduleNames)
	if not moduleServer then
		error(string.format("Could not find module: %s", fqName), 3)
	end

	return moduleServer
end

ModuleLoader.SAFE_REQUIRE_WARN_TIMEOUT = .5

--- A wrapper for require which causes a warning if the module is taking too long to load.
-- @private
function ModuleLoader:_safe_require(mod, requiring_mod)
	local startTime = os.clock()
	local conn
	conn = RunService.Stepped:Connect(function ()
		if os.clock() >= startTime + self.SAFE_REQUIRE_WARN_TIMEOUT then
			warn(string.format("%s -> %s is taking too long", tostring(requiring_mod), tostring(mod)))
			if conn then
				conn:Disconnect()
				conn = nil
			end
		end
	end)

	local retval
	local success, err = pcall(function ()
		retval = require(mod)
	end)

	if not success then
		if type(retval) == "nil" and string.find(err, "exactly one value") then
			error("Module did not return exactly one value: " .. mod:GetFullName(), 3)
		else
			error("Module " .. mod:GetFullName() .. " experienced an error while loading: " .. err, 3)
		end
	end

	if conn then
		conn:Disconnect()
		conn = nil
	end

	return retval
end

--- When called by a function that replaces `require`, this function returns the LuaSourceContainer
-- which called `require`.
--@private
function ModuleLoader._getRequiringScript(_)
	local array = string.split(debug.traceback(), ".")
	return string.match(array[#array], "^(.+):")
end

-- function ModuleLoader._getRequiringScript1()
-- 	return getfenv(3).script
-- end

--- Basic memoization pattern
-- @private
ModuleLoader._cache = {}

--- Main logic of all flavors of require calls.
-- @private
function ModuleLoader:_require(object, requiring_script)
	if not requiring_script then
		requiring_script = self:_getRequiringScript()
	end

	self:_print(string.format(
		"%s -> %s%s",
		tostring(requiring_script),
		tostring(object),
		(self._cache[object] ~= nil and " (cached)" or "")
	))

	if self._cache[object] then
		return self._cache[object]
	end

	local object_type = typeof(object)
	local retval
	if object_type == "number" then
		-- Use plain require instead of _safe_require, as asset IDs need to load
		retval = require(object)
	elseif object_type == "Instance" then
		if object:IsA("ModuleScript") then
			retval = self:_safe_require(object, requiring_script)
		else
			error("Non-ModuleScript passed to require: " .. object:GetFullName(), 2)
		end
	elseif object_type == "string" then
		local moduleScript = assert(self:_findModule(object), string.format("Could not find module: %s", tostring(object)))
		retval = self:_safe_require(moduleScript, requiring_script)
	elseif object_type == "nil" then
		error("require expects ModuleScript, asset id or string", 2)
	else
		error("Unknown type passed to require: " .. object_type, 2)
	end

	assert(retval, "No retval from require")
	self._cache[object] = retval
	return retval
end

--- The main `require` overload.
-- @param object An object normally passed to require OR a string
function ModuleLoader.require(object)
	local requiringScript = ModuleLoader:_getRequiringScript()
	return ModuleLoader:_require(object, requiringScript)
end

--- Alias for calling @{ModuleLoader.require}, useful when using ModuleLoader as a `require` replacement.
function ModuleLoader:__call(object)
	local requiringScript = self:_getRequiringScript()
	return self:_require(object, requiringScript)
end

--- Like @{ModuleLoader.require|require}, but returns nil if not ran on the server.
function ModuleLoader.server(object)
	local requiringScript = ModuleLoader:_getRequiringScript()
	if isServer then
		return ModuleLoader:_require(object, requiringScript)
	else
		return nil
	end
end

--- Like @{ModuleLoader.require|require}, but returns nil if not ran on a client.
function ModuleLoader.client(object)
	local requiringScript = ModuleLoader:_getRequiringScript()
	if isClient then
		return ModuleLoader:_require(object, requiringScript)
	else
		return nil
	end
end

--- Copies "Replicated" folders in ServerScriptService modules to ReplicatedStorage, renaming them.
-- Also signals that all libraries have been replicated.
-- @private
function ModuleLoader._replicateLibraries()
	-- Search for modules with "-Replicated" at the end and replicate them
	-- Alternatively, child folder named "Replicated" is moved and renamed
	for _, child in ipairs(ServerScriptService:GetChildren()) do
		if child:IsA("Folder") then
			if string.find(child.Name, "%-Replicated$") then
				child.Name = string.sub(child.Name, 1, #child.Name - 11)
				child.Parent = ReplicatedStorage
			elseif child:FindFirstChild("Replicated") then
				local rep = child.Replicated
				rep.Name = child.Name
				rep.Parent = ReplicatedStorage
			end
		end
	end

	ModuleLoader._signalAllLibrariesReplicated()
end

ModuleLoader.ALL_LIBRARIES_REPLICATED = "AllLibrariesReplicated"
--- Signals to clients that all libraries have been replicated by creating a foldr in ReplicatedStorage.
-- @private
function ModuleLoader._signalAllLibrariesReplicated()
	local allLibrariesReplicatedTag = Instance.new("Folder")
	allLibrariesReplicatedTag.Name = ModuleLoader.ALL_LIBRARIES_REPLICATED
	allLibrariesReplicatedTag.Parent = ReplicatedStorage
end

--- Waits for the server to signal that all libraries have been replicated.
-- @private
function ModuleLoader._waitForLibrariesToReplicate()
	ReplicatedStorage:WaitForChild(ModuleLoader.ALL_LIBRARIES_REPLICATED)
end

--- Returns the version of the ModuleLoader being used
-- @function ModuleLoader:__tostring
function ModuleLoader:__tostring()
	return string.format("<ModuleLoader %s>", self.VERSION)
end

-- Server should replicate
if isServer then
	ModuleLoader._replicateLibraries()
end

-- Client should wait for modules to replicate
if isClient then
	ModuleLoader._waitForLibrariesToReplicate()
end

return ModuleLoader
