--- @module Maid.test
-- Tests for Maid class

local Maid = require(script.Parent)

local MaidTests = {}

MaidTests["test_Maid:addTask(function)"] = function ()
	-- Setup
	local myFunctionDidRun = false
	local function myFunction()
		myFunctionDidRun = true
	end

	-- Maid
	local maid = Maid.new()
	maid:addTask(myFunction)
	maid:cleanup()
	maid = nil

	assert(myFunctionDidRun, "Maid should call a function added as a task")
end

MaidTests["test_Maid:addTask(connection)"] = function ()
	-- Setup
	local myFunctionDidRun = false
	local function myFunction()
		myFunctionDidRun = true
	end

	local object = Instance.new("Folder")
	object.Name = "A"
	local connection = object.Changed:Connect(myFunction)

	-- Maid
	local maid = Maid.new()
	maid:addTask(connection)
	maid:cleanup()
	maid = nil

	-- Cause Changed to fire
	object.Name = "B"

	assert(not myFunctionDidRun, "Maid should disconnect a connection added as a task")
end

MaidTests["test_Maid:addTask(Instance)"] = function ()
	-- Setup
	local object = Instance.new("Folder")
	object.Parent = workspace

	-- Maid
	local maid = Maid.new()
	maid:addTask(object)
	maid:cleanup()
	maid = nil

	assert(not object.Parent, "Maid should disconnect a connection added as a task")
end

MaidTests["test_Maid:addTask(cleanup)"] = function ()
	-- Setup
	local myFunctionDidRun = false
	local function myFunction()
		myFunctionDidRun = true
	end

	-- Maid.new
	local maid = Maid.new()
	maid:addTask({ cleanup = myFunction })
	maid:cleanup()
	maid = nil

	assert(myFunctionDidRun, "Maid should call cleanup on tasks that have it")
end

return MaidTests
