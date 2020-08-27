--- @module StateMachine.test
-- Tests for StateMachine class

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local StateMachine = require(Modules:WaitForChild("StateMachine"))
local State = require(Modules.StateMachine:WaitForChild("State"))

local StateMachineTests = {}

StateMachineTests["test_StateMachine"] = function ()
	-- Setup
	local onEnterDidRun = false
	local onLeaveDidRun = false

	-- StateMachine
	local sm = StateMachine.new()
	local state1 = sm:newState("state1")
	state1.onLeave:connect(function ()
		onLeaveDidRun = true
	end)
	local state2 = sm:newState("state2")
	state2.onEnter:connect(function ()
		onEnterDidRun = true
	end)

	assert(sm:hasState("state1"), "StateMachine:newState should add the constructed state")

	-- First, transition to first state
	sm:transition(state1)
	assert(sm:isInState(state1), "StateMachine:transition should transition the StateMachine to the given state")

	-- Then, transition to second state
	sm:transition(state2)

	-- Check that things worked fine
	assert(onLeaveDidRun, "State.onLeave should fire when a state is left")
	assert(onEnterDidRun, "State.onEnter should fire when a state is entered")

	sm:cleanup()
end

StateMachineTests["test_StateMachine:newSubmachine(state)"] = function ()
	-- StateMachine
	local sm = StateMachine.new()

	-- States
	local state1 = sm:newState("state1")
	local state2 = sm:newState("state2")
	sm:transition(state1)

	-- Sub-StateMachines
	local subm1, subm1inactive, subm1active = sm:newSubmachine(state1)
	local subm1state1 = subm1:newState("subm1state1")
	local subm2, subm2inactive, subm2active = sm:newSubmachine(state2)
	local subm2state1 = subm1:newState("subm2state1")

	assert(subm1:isInState(subm1active), "Submachine should start in Active state when parent StateMachine is in the submachine state")
	assert(subm2:isInState(subm2inactive), "Submachine should start in Inactive state when parent StateMachine is not in the submachine state")

	sm:transition(state2)
	assert(subm1:isInState(subm1inactive), "After transitioning away from parent state, submachine should transition to Inactive state")
	assert(subm2:isInState(subm2active), "After transitioning to parent state, submachine should transition to Active state")
	
	subm2:transition(subm2state1)
	assert(subm2:isInState(subm2state1), "Submachine should be able to transition while parent state is active")

	sm:transition(state1)
	assert(subm2:isInState(subm2inactive), "Submachine should return to Inactivate state when parent StateMachine State is left")
end

return StateMachineTests
