--[[-- A mechanism that transitions between @{State|states}.

A **StateMachine** (or machine) is a mechanism that @{StateMachine:transition|transitions} between several
@{State|states} that have been @{StateMachine:addState|added}, usually through @{StateMachine:newState|newState}.
When a transition is performed, the previous state is @{State:leave|left}, the
@{StateMachine.onTransition|onTransition} event fires, and the new state is @{State:enter|entered}.
Machines do not begin in any state in particular, but rather a nil state.

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
local MyMachine = setmetatable({}, StateMachine)
MyMachine.__index = MyMachine

function MyMachine.new()
	local self = setmetatable(StateMachine.new(), MyMachine)

	-- States 
	self.defaultState = self:newState("default")
	self.spamState = self:newState("spam")
	self.eggsState = self:newState("eggs")
	self.maid:addTask(self.spamState.onEnter:connect(function ()
		self:onSpamStateEntered()
	end))

	-- Transition counter
	self.transitionCounter = 0

	-- Default state
	self:transition(self.defaultState)

	return self
end

function MyMachine:transition(...)
	StateMachine.transition(self, ...) -- call super
	self.transitionCounter = self.transitionCounter + 1
	print("Transitions: " .. self.transitionCounter)
end

function MyMachine:onSpamStateEntered()
	print("Spam!")
end
```

##### Usage

```lua
local myMachine = MyMachine.new()
myMachine:transition("spam")
myMachine:transition("eggs")
```

#### Sub-machines

Certain @{State|states} may control their own StateMachine (a sub-StateMachine or submachine). When a state with a sub-machine is entered,
the submachine enters the "Active" state. Upon leaving, it enters the "Inactive" state.
]]
--@classmod StateMachine

local Maid = require(script.Parent:WaitForChild("Maid"))
local Event = require(script.Parent:WaitForChild("Event"))

local State = require(script:WaitForChild("State"))

local StateMachine = {}
StateMachine.__index = StateMachine

--- The @{State} class used when creating a @{StateMachine:newState|new state} via this machine.
-- @field StateMachine.StateClass
StateMachine.StateClass = State

--- The @{StateMachine} class used when creating a @{StateMachine:newSubmachine|new submachine} for a state via this machine.
-- @field StateMachine.SubStateMachineClass
StateMachine.SubStateMachineClass = StateMachine

--- Construct a new StateMachine.
-- The new machine has no states @{StateMachine:addState|added} to it, and is not in any state to begin with.
-- @constructor
-- @treturn StateMachine The new state machine with no @{State|states}.
function StateMachine.new()
	local self = setmetatable({
		--- Refers to the current @{State} the machine is in, if any. Use @{StateMachine:isInState|isInState}
		-- to check the current state by object or id.
		state = nil;

		--- Dictionary of @{State|states} by @{State.id|id} that have been @{StateMachine:addState|added}
		-- @treturn dictionary
		states = {};

		--- A @{Maid} invoked upon @{StateMachine:cleanup|cleanup}
		-- Cleans up @{StateMachine.onTransition|onTransition} and states constructed
		-- through @{StateMachine.newState|newState}.
		-- @treturn Maid
		maid = Maid.new();

		--- Fires when the machine @{StateMachine:transition|transitions} between states.
		-- @event onTransition
		-- @tparam State oldState The state which the machine is leaving, if any
		-- @tparam State newState The state whihc the machine is entering, if any
		onTransition = Event.new();

		--- A flag which enables transition @{StateMachine:print|printing} for this machine.
		-- @treturn boolean
		debugMode = false;
	}, StateMachine)
	self.maid:addTask(self.onTransition)
	return self
end

--- Returns a string with the current @{State} this machine is in (if any), calling @{State:__tostring}.
function StateMachine:__tostring()
	return ("<StateMachine (%s)>"):format(self.state and tostring(self.state) or "<nil>")
end

--- Wraps the default `print` function; does nothing if @{StateMachine.debugMode|debugMode} is false.
function StateMachine:print(...)
	if self.debugMode then
		print(...)
	end
end

--- Clean up resources used by this machine by calling @{Maid:cleanup|cleanup} on
-- this machine's @{StateMachine.maid|maid}.
-- States created with @{StateMachine:newState|newState} are cleaned up as well.
function StateMachine:cleanup()
	if self.maid then
		self.maid:cleanup()
		self.maid = nil
	end
	self.states = nil
end

--- Add a @{State|State} to this machine's @{StateMachine.states|states}.
-- @tparam State state A @{State|State} object
-- @return The @{State|state} that was added.
function StateMachine:addState(state)
	--if not state or getmetatable(state) ~= State then error("StateMachine:addState() expects state", 2) end
	self.states[state.id] = state
	return state
end

--- @{State.new|Construct} and @{StateMachine:addState|add} a new @{State|state} of type
-- @{StateMachine.StateClass|StateClass} (by default, @{State}) for this machine.
-- The state is @{Maid:addTask|added} as a @{StateMachine.maid|maid} task.
-- @return The newly constructed @{State|state} .
function StateMachine:newState(...)
	local state = self.StateClass.new(self, ...)
	self.maid:addTask(state)
	return self:addState(state)
end

--- Determines whether this machine has a @{State|state} with the given id.
-- @tparam string id The id of the state to check. 
-- @treturn boolean Whether the machine has a @{State|state} with the given id. 
function StateMachine:hasState(id)
	return self.states[id] ~= nil
end

--- Get a @{State|state} by id that was previously @{StateMachine:addState|added} to this machine.
-- @tparam string id The id of the state.
-- @treturn State The state, or nil if no state was added with the given id.
function StateMachine:getState(id)
	return self.states[id]
end

--- If given an id of a state, return the state with that id (or produce an error no such state exists).
-- Otherwise, returns the given state.
-- @private
function StateMachine:_stateArg(stateOrId)
	local state = stateOrId
	if type(stateOrId) == "string" then
		state = self:hasState(stateOrId)
		    and self:getState(stateOrId)
		     or error("Unknown state id: " .. tostring(stateOrId))
	--else
		-- TODO: verify stateOrId is in fact a State
	end
	return state
end

--- Returns whether the machine is currently in the given state or state with given id
-- @tparam ?State|string state The state or id of the state to check
-- @treturn boolean
function StateMachine:isInState(state)
	assert(type(state) ~= "nil", "Must provide non-nil state")
	return self.state == self:_stateArg(state)
end

--- Transition the machine to another state, firing all involved events in the process.
-- This method will @{StateMachine:print|print} transitions before making them if the machine
-- has @{StateMachine.debugMode|debugMode} set.
-- Events are fired in the following order: @{State.onLeave|old state onLeave},
-- @{StateMachine.onTransition|machine onTransition}, then finally @{State.onEnter|new state onEnter}.
-- @tparam ?State|string stateNew The state to which the machine should transition, or its `id`.
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

--[[-- Create a StateMachine of type @{StateMachine.SubStateMachineClass|SubStateMachineClass}, given a @{State|state}.
Two @{StateMachine:newState|new states} are created on the sub-StateMachine with ids "Active" and "Inactive":

  * When the parent machine @{State.onEnter|enters} the given state, the sub-StateMachine transitions to "Active".
  * When the parent machine @{State.onLeave|leaves} the given state, the sub-StateMachine transitions to "Inactive".

The sub-StateMachine is @{Maid:addTask|added} as a task to this machine's @{StateMachine.maid|maid}.
]]
-- @tparam State state The @{State} to implement the new sub-machine.
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

return StateMachine
