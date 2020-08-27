--- @module Modules.test
-- Tests for ModuleLoader module

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local ModuleLoader = require(Modules)

local ModuleLoaderTests = {}

ModuleLoaderTests["test_ModuleLoader.require(ModuleScript)"] = function ()
	local scr = script.PlainModule
	local PlainModule = require(scr)
	assert(ModuleLoader(scr) == PlainModule,
		   "Calling ModuleLoader.__call with a ModuleScript should return the same as require")
	assert(ModuleLoader.require(scr) == PlainModule,
		   "Calling ModuleLoader.require with a ModuleScript should return the same as require")
end

ModuleLoaderTests["test_ModuleLoader.require()_client"] = function ()
	local someClientNamespace         = assert(ReplicatedStorage:FindFirstChild("SomeClientNamespace"), "SomeClientNamespace missing")
	local someClientModule            = assert(someClientNamespace:FindFirstChild("SomeClientModule"), "SomeClientModule missing")
	local someClientModuleWithAPeriod = assert(someClientNamespace:FindFirstChild("SomeClientModule.WithAPeriod"), "SomeClientModule.WithAPeriod missing")

	local SomeClientModule = require(someClientModule)
	assert(ModuleLoader("SomeClientNamespace:SomeClientModule") == SomeClientModule,
	       "Calling ModuleLoader.require should properly find modules in client namespaces")

	local SomeClientModuleWithAPeriod = require(someClientModuleWithAPeriod)
	local SomeClientModuleWithAPeriod_ = ModuleLoader("SomeClientNamespace:SomeClientModule%.WithAPeriod")
	assert(SomeClientModuleWithAPeriod_ == SomeClientModuleWithAPeriod,
	       "Calling ModuleLoader.require should properly find modules whose names have %-escaped periods")
end

ModuleLoaderTests["test_ModuleLoader.require()_server"] = function ()
	local someServerNamespace         = assert(ServerScriptService:FindFirstChild("SomeServerNamespace"), "SomeServerNamespace missing")
	local someServerModule            = assert(someServerNamespace:FindFirstChild("SomeServerModule"), "SomeServerModule missing")

	local SomeServerModule = require(someServerModule)
	assert(ModuleLoader("SomeServerNamespace:SomeServerModule") == SomeServerModule,
	       "Calling ModuleLoader.require should properly find modules in server namespaces")
end

ModuleLoaderTests["test_ModuleLoader.require()_server_replicated"] = function ()
	-- Normally this is in ServerScriptService.SomeServerNamespace.Replicated, but the module should
	-- have moved this to ReplicatedStorage.SomeServerNamespace.SomeReplicatedBit !
	local someServerNamespaceReplicated = assert(ReplicatedStorage:FindFirstChild("SomeServerNamespace"), "SomeServerNamespace (replicated) missing")
	local someReplicatedBit           = assert(someServerNamespaceReplicated:FindFirstChild("SomeReplicatedBit"), "SomeReplicatedBit missing")

	local SomeReplicatedBit = require(someReplicatedBit)
	assert(ModuleLoader("SomeServerNamespace:SomeReplicatedBit") == SomeReplicatedBit,
	       "Calling ModuleLoader.require should properly find replicated parts of server namespaces")
end

return ModuleLoaderTests
