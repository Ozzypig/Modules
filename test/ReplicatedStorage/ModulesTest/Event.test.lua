--- @module Event.test
-- Tests for Event class

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Event = require(Modules:WaitForChild("Event"))

local EventTests = {}

EventTests["test_Event"] = function ()
	-- Utility
	local myFunctionDidRun = false
	local function myFunction()
		myFunctionDidRun = true
	end

	-- Event.new
	local event = Event.new()
	assert(type(event) ~= "nil")
 
	-- Event:connect
	local connection = event:connect(myFunction)
	assert(type(connection) ~= "nil", "Event:connect should return a connection")

	-- Event:fire
	event:fire()
	assert(myFunctionDidRun, "Event:fire should run connected functions")

	-- Connection:disconnect()
	myFunctionDidRun = false
	connection:disconnect()
	connection = nil
	event:fire()
	assert(not myFunctionDidRun, "Event:fire should not run disconnected functions")

	-- Event:cleanup
	event:cleanup()
	event = nil
end

return EventTests
