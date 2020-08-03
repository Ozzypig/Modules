--- A state of a @{StateMachine}.
-- You probably want to use @{StateMachine:newState} to create one.
-- @classmod StateMachine.State

local Maid = require(script.Parent.Parent:WaitForChild("Maid"))
local Event = require(script.Parent.Parent:WaitForChild("Event"))

local State = {}
State.__index = State

--- Fires when a @{StateMachine} @{StateMachine:transition|transitions} into this state.
-- @event onEnter

--- Fires when a @{StateMachine} @{StateMachine:transition|transitions} out of this state.
-- @event onLeave

--- Construct a new state.
-- @tparam StateMachine machine The `StateMachine` to which the new state should belong.
-- @tparam string id An identifier for the new state, must be unique within the owning `StateMachine`.
-- @tparam[opt] function onEnterFunction A `function` to connect to the onEnter event upon creation.
-- @constructor State.new
-- @see StateMachine:newState
-- @usage local state = State.new(machine, id, onEnterFunction)
-- @usage local state = machine:newState(id, onEnterFunction)
function State.new(machine, id, onEnterFunction)
	if type(id) ~= "string" then error("State.new expects string id", 3) end
	local self = setmetatable({
		machine = machine;
		id = id;
		maid = Maid.new();
		onEnter = Event.new();
		onLeave = Event.new();
		submachineInactiveStates = {};
		submachineActiveStates = {};
	}, State)
	self.maid:addTask(self.onEnter)
	self.maid:addTask(self.onLeave)
	
	if type(onEnterFunction) == "function" then
		self.maid:addTask(self.onEnter:connect(onEnterFunction))
	elseif type(onEnterFunction) == "nil" then
		-- that's ok
	else
		error("State.new() was given non-function onEnterFunction (" .. type(onEnterFunction) .. ", " .. tostring(onEnterFunction) .. ")")
	end	
	
	return self
end

function State:__tostring()
	return ("<State %q>"):format(self.id)
end

function State:cleanup()
	self.submachineInactiveStates = nil
	self.submachineActiveStates = nil
	self.machine = nil
	if self.maid then
		self.maid:cleanup()
		self.maid = nil
	end
end

--- Fires the {@StateMachine.State.onEnter|onEnter} event.
-- Passes all arguments to `Event:fire`.
function State:enter(...)
	self.onEnter:fire(...)
	for submachine, activeState in pairs(self.submachineActiveStates) do
		if not submachine:isInState(activeState) then
			submachine:transition(activeState)
		end
	end
end

--- Fires the {@StateMachine.State.onEnter|onEnter} event.
-- Passes all arguments to `Event:fire`.
function State:leave(...)
	self.onLeave:fire(...)
	for submachine, inactiveState in pairs(self.submachineInactiveStates) do
		if not submachine:isInState(inactiveState) then
			submachine:transition(inactiveState)
		end
	end
end

--- Orders the owning @{StateMachine} to @{StateMachine:transition|transition} to this state.
-- @return The result of the @{StateMachine:transition|transition}.
function State:transition()
	return self.machine:transition(self)
end

function State:addSubmachine(submachine, inactiveState, activeState)
	self.submachineInactiveStates[submachine] = inactiveState
	self.submachineActiveStates[submachine] = activeState
	return inactiveState, activeState
end

return State
