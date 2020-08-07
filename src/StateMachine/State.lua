--[[-- A uniquely identified state of a @{StateMachine}.
A **State** is an object with a unique @{State.id|id} that represents one possible state of a parent @{StateMachine}.
A state can be associated with only one machine (its parent), and its id must be unique within its machine.
When the parent machine has entered a state, that state is considered @{State:isActive|active} until it
@{State:leave|leaves} the state.

States can be @{State.new|constructed}, @{StateMachine:addState|added} and @{State:cleanup|cleaned up} manually,
or they may be created through @{StateMachine:newState}. For manually-constructed states, it's helpful to
@{Maid:addTask|add} the state as a task to the machine's @{StateMachine.maid|maid} so it is cleaned up

#### Event-based Usage

```lua
local sm = StateMachine.new()

-- Create some states
local stateGame = sm:newState("game")
local stateShop = sm:newState("shop")
stateShop.onEnter:connect(function ()
	print("Welcome to the shop!")
end)
stateShop.onLeave:connect(function ()
	print("Come back soon.")
end)

-- Make some transitions
sm:transition("game")
sm:transition("shop") --> Welcome to the shop!
sm:transition("game") --> Come back soon.
```

#### Subclass Usage

```lua
local CounterState = setmetatable({}, State)
CounterState.__index = CounterState

function CounterState.new(...)
	local self = setmetatable(State.new(...), CounterState)
	
	-- Tracks number of times it has been transitioned to
	self.transitionCount = 0

	return self
end

function CounterState:enter(...)
	State.enter(self, ...) -- call super
	self.transitionCount = self.transitionCount + 1
end
```

##### Usage

```lua
local sm = StateMachine.new()
sm.StateClass = CounterState -- StateMachine:newState now uses CounterState

local firstState = sm:newState("first")
sm:newState("second")
sm:newState("third")

sm:transition("first")
sm:transition("second")
sm:transition("first")

print("Transitions: " .. firstState.transitionCount) --> Transitions: 2
```

]]
-- @classmod State

local Maid = require(script.Parent.Parent:WaitForChild("Maid"))
local Event = require(script.Parent.Parent:WaitForChild("Event"))

local State = {}
State.__index = State

--- Construct a new state given the @{StateMachine} it should belong to, its unique id within this machine,
-- and optionally a function to immediately connect to the @{State.onEnter|onEnter} event.
-- This is called by @{StateMachine:newState}, automatically providing the machine to this constructor.
-- @tparam StateMachine machine The `StateMachine` to which the new state should belong.
-- @tparam string id An identifier for the new state, must be unique within the parent `StateMachine`.
-- @tparam[opt] function onEnterCallback A `function` to immediately connect to @{State.onEnter|onEnter}
-- @constructor
function State.new(machine, id, onEnterCallback)
	if type(id) ~= "string" then error("State.new expects string id", 3) end
	local self = setmetatable({
		--- The parent @{StateMachine} which owns this state and can @{StateMachine:transition|transition} to it.
		-- @treturn StateMachine
		machine = machine;

		--- The unique string that identifies this state in its machine
		-- @treturn string
		id = id;

		--- A @{Maid} invoked upon @{StateMachine:cleanup|cleanup}
		-- @treturn Maid
		maid = Maid.new();
		
		--- Fires when the parent @{State.machine|machine} @{StateMachine:transition|transitions} into this state.
		-- @event onEnter
		-- @tparam State prevState The @{State} which the parent {@State.machine|machine} had left (if any)
		onEnter = Event.new();
		
		--- Fires when parent @{State.machine|machine} @{StateMachine:transition|transitions} out of this state.
		-- @event onLeave
		-- @tparam State nextState The @{State} which the parent {@State.machine|machine} will enter (if any)
		onLeave = Event.new();

		--- Tracks the "Active" States of any @{StateMachine:newSubmachine|sub-machines} for this state,
		-- transitioning to them when this state is @{State.onEnter|onEnter}.
		-- @private
		submachineActiveStates = {};

		--- Tracks the "Inactive" States of any @{StateMachine:newSubmachine|sub-machines} for this state,
		-- transitioning to them when this state is @{State.onLeave|onLeave}.
		-- @private
		submachineInactiveStates = {};
	}, State)
	self.maid:addTask(self.onEnter)
	self.maid:addTask(self.onLeave)
	
	if type(onEnterCallback) == "function" then
		self.maid:addTask(self.onEnter:connect(onEnterCallback))
	elseif type(onEnterCallback) == "nil" then
		-- that's ok
	else
		error("State.new() was given non-function onEnterCallback (" .. type(onEnterCallback) .. ", " .. tostring(onEnterCallback) .. ")")
	end	
	
	return self
end

--- Returns a string with this state's @{State.id|id}.
function State:__tostring()
	return ("<State %q>"):format(self.id)
end

--- Clean up resources used by this state.
-- Careful, this function doesn't remove this state from the parent @{State.machine|machine}!
function State:cleanup()
	self.submachineInactiveStates = nil
	self.submachineActiveStates = nil
	self.machine = nil
	if self.maid then
		self.maid:cleanup()
		self.maid = nil
	end
end

--- Called when the parent @{State.machine|machine} enters this state, firing
-- the @{State.onEnter|onEnter} event with all given arguments.
-- If this state has any @{StateMachine:newSubmachine|sub-machines},
-- they will transition to the "Active" state.
function State:enter(...)
	self.onEnter:fire(...)
	for submachine, activeState in pairs(self.submachineActiveStates) do
		if not submachine:isInState(activeState) then
			submachine:transition(activeState)
		end
	end
end

--- Called when the parent @{State.machine|machine} leaves this state, firing
-- the @{State.onLeave|onLeave} event with all given arguments.
-- If this state has any @{StateMachine:newSubmachine|sub-machines},
-- they will transition to the "Inactive" state.
function State:leave(...)
	self.onLeave:fire(...)
	for submachine, inactiveState in pairs(self.submachineInactiveStates) do
		if not submachine:isInState(inactiveState) then
			submachine:transition(inactiveState)
		end
	end
end

--- Returns whether the parent @{State.machine|machine} is @{StateMachine:isInState|currently in} this state.
-- @treturn boolean
function State:isActive()
	return self.machine:isInState(self)
end

--- Orders the parent @{State.machine|machine} to @{StateMachine:transition|transition} to this state.
-- @return The result of the @{StateMachine:transition|transition}.
function State:transition()
	return self.machine:transition(self)
end

--- Helper function for @{StateMachine:newSubmachine}
-- @private
function State:addSubmachine(submachine, inactiveState, activeState)
	self.submachineInactiveStates[submachine] = inactiveState
	self.submachineActiveStates[submachine] = activeState
	return inactiveState, activeState
end

return State
