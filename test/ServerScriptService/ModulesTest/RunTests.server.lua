--- Invokes TestRunner with the tests in ServerTests

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestRunner = require(ReplicatedStorage:WaitForChild("TestRunner"))

local testContainer = ReplicatedStorage:WaitForChild("ModulesTest")

local function main()
	local testRunner = TestRunner.gather(testContainer)
	testRunner:runAndReport()
end
main()
