--- A finite state machine implementation with @{StateMachine.State|states} and @{StateMachine:transition|transitions}.
-- @classmod StateMachine

local Maid = require(script.Parent:WaitForChild("Maid"))
local Event = require(script.Parent:WaitForChild("Event"))

local State = require(script:WaitForChild("State"))

local StateMachine = {}
StateMachine.__index = StateMachine

StateMachine.StateClass = State
StateMachine.SubStateMachineClass = StateMachine

--- An @{Event} that fires when the machine transitions to a new state
-- @event onTransition
StateMachine.onTransition = nil

--- Construct a new StateMachine.
-- @treturn StateMachine The new state machine with no @{StateMachine.State|states}.
-- @constructor StateMachine.new
-- @usage local mach = StateMachine.new()
function StateMachine.new()
	local self = setmetatable({
		state = nil;
		states = {};
		maid = Maid.new();
		onTransition = Event.new();
		debugMode = false;
	}, StateMachine)
	self.maid:addTask(self.onTransition)
	return self
end

function StateMachine:__tostring()
	return ("<StateMachine (%s)>"):format(self.state and tostring(self.state) or "<nil>")
end

--- Alias of Lua's print function, ignored if this StateMachine's debugMode is false.
function StateMachine:print(...)
	if self.debugMode then
		print(...)
	end
end

--- Clean up resources used by the state machine (does not clean up states automatically)
function StateMachine:cleanup()
	if self.maid then
		self.maid:cleanup()
		self.maid = nil
	end
	self.states = nil
end

--- Add a @{StateMachine.State|State} to the set of this StateMachine's states.
-- @tparam StateMachine.State state A @{StateMachine.State|State} object
-- @return The @{StateMachine.State|state} that was added.
function StateMachine:addState(state)
	--if not state or getmetatable(state) ~= State then error("StateMachine:addState() expects state", 2) end
	self.states[state.id] = state
	return state
end

--- @{StateMachine.State.new|Construct} and @{StateMachine:addState|add} a new @{StateMachine.State|state}.
-- @return The newly constructed @{StateMachine.State|state} .
function StateMachine:newState(...)
	local state = self.StateClass.new(self, ...)
	self.maid:addTask(state)
	return self:addState(state)
end

--- Create a sub-StateMachine given a @{StateMachine.State|state}. The new sub-StateMachine is created with "Active"
-- and "Inactive" states. When the parent StateMachine transitions ot the given state, the sub-StateMachine transitions
-- to/from the Active/Inactive states, respectively.
function StateMachine:newSubmachine(state)
	local submachine = self.SubStateMachineClass.new()
	self.maid:addTask(submachine)

	local inactiveState = submachine:newState("Inactive")
	local activeState = submachine:newState("Active")

	-- Initial transition
	if self:isInState(state) then
		submachine:transition(activeState)
	else
		submachine:transition(inactiveState)
	end

	return submachine, state:addSubmachine(submachine, inactiveState, activeState)
end

--- Get a @{StateMachine.State|state} by id that was previously @{StateMachine:addState|added}.
-- @return The state, or nil if no state was added with the given id.
function StateMachine:getState(id)
	return self.states[id]
end

--- If given an id of a state, return the state with that id (or produce an error no such state exists).
-- Otherwise, returns the given state.
function StateMachine:_stateArg(stateOrId)
	local state = stateOrId
	if type(stateOrId) == "string" then
		state = self:hasState(stateOrId)
		    and self:getState(stateOrId)
		     or error("Unknown state id: " .. tostring(stateOrId))
	else
		-- TODO: verify stateOrId is in fact a State
	end
	return state
end

--- Check if this machine has a @{StateMachine.State|state} with a given id.
-- @tparam string id The id of the state to check. 
-- @treturn bool Whether the machine has a @{StateMachine.State|state} with the given id. 
function StateMachine:hasState(id)
	return self.states[id] ~= nil
end

--- Transition the machine to another state, firing all involved events in the process.
-- This method will @{StateMachine:print|print} transitions before making them if the machine has debugMode set.
-- Events are fired in the following order: @{StateMachine.State.onLeave|old state onLeave},
-- @{StateMachine.onTransition|machine onTransition}, then finally @{StateMachine.State.onEnter|new state onEnter}.
-- @tparam ?StateMachine.State|string stateNew The state to which the machine should transition, or its `id`.
function StateMachine:transition(stateNew)
	if type(stateNew) == "string" then stateNew = self:hasState(stateNew) and self:getState(stateNew) or error("Unknown state id: " .. tostring(stateNew), 2) end
	if type(stateNew) == "nil" then error("StateMachine:transition() requires state", 2) end
	--if getmetatable(stateNew) ~= State then error("StateMachine:transition() expects state", 2) end
	 
	local stateOld = self.state
	self:print(("%s -> %s"):format(stateOld and stateOld.id or "(none)", stateNew and stateNew.id or "(none)"))
	
	self.state = stateNew
	if stateOld then stateOld:leave(stateNew) end
	self.onTransition:fire(stateOld, stateNew)
	if stateNew then stateNew:enter(stateOld) end
end

--- Determine whether the state machine is in the given state or state with given id
function StateMachine:isInState(state)
	assert(type(state) ~= "nil", "Must provide non-nil state")
	return self.state == self:_stateArg(state)
end

return StateMachine
