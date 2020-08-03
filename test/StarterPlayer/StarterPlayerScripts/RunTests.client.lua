--- Invokes TestRunner with the tests in ClientTests
local TestRunner = require(game:GetService("ReplicatedStorage"):WaitForChild("TestRunner"))

local testContainer = script.Parent.ClientTests

local function main()
	local testRunner = TestRunner.gather(testContainer)
	testRunner:runAndReport()
end
main()
