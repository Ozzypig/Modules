--- @module Event.test
-- Tests for Event class

local Event = require(script.Parent)

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
