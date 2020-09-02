--- Given a table of functions ("tests"), runs each function and records the results
--@classmod TestRunner

local TestRunner = {}
TestRunner.__index = TestRunner
TestRunner.MODULESCRIPT_NAME_PATTERN = "%.?[tT]est$"
TestRunner.FUNCTION_NAME_PATTERN_PREFIX = "^[tT]est_?"
TestRunner.FUNCTION_NAME_PATTERN_POSTFIX = "_?[tT]est"

--- Determines if the given name of a function indicates that it is
-- a test function.
function TestRunner.functionNameIndicatesTest(name)
	return name:match(TestRunner.FUNCTION_NAME_PATTERN_PREFIX)
	    or name:match(TestRunner.FUNCTION_NAME_PATTERN_POSTFIX)
end

--- Determines whether the given object is a ModuleScript containing tests
function TestRunner.isTestModule(object)
	return object:IsA("ModuleScript") and object.Name:match(TestRunner.MODULESCRIPT_NAME_PATTERN)
end

--- Recurses an object for test module scripts and calls foundTestModuleScript for each one found
function TestRunner.recurseForTestModules(object, foundTestModuleScript)
	if TestRunner.isTestModule(object) then
		foundTestModuleScript(object)
	end
	for _, child in pairs(object:GetChildren()) do
		TestRunner.recurseForTestModules(child, foundTestModuleScript)
	end
end

--- Constructs a TestRunner using tests gathered from a root object,
-- which is recursed for any ModuleScripts whose names end in the given
-- pattern, "test"/"Test" or ".test"/".Test"
function TestRunner.gather(object)
	local tests = {}     --[name] = func
	local testNames = {} --[func] = name
	local numTests = 0

	-- Add tests to the table
	TestRunner.recurseForTestModules(object, function (testModule)
		local testsToAdd = require(testModule)
		assert(type(testsToAdd) == "table", ("%s should return a table of test functions, returned %s: %s"):format(
			testModule:GetFullName(), type(testsToAdd), tostring(testsToAdd)
		))
		local testsInThisModule = 0
		for name, func in pairs(testsToAdd) do
			if type(func) == "function" and TestRunner.functionNameIndicatesTest(name) then
				tests[name] = assert(not tests[name] and func, ("Test with name %s already exists"):format(name))
				testNames[func] = assert(not testNames[func], ("Duplicate tests: %s and %s"):format(name or "nil", testNames[func] or "nil"))
				numTests = numTests + 1
				testsInThisModule = testsInThisModule + 1
			end
		end
		assert(testsInThisModule > 0, ("%s should contain at least one test function"):format(testModule:GetFullName()))
	end)

	assert(numTests > 0, ("TestRunner.gather found no tests in %s"):format(object:GetFullName()))

	return TestRunner.new(tests)
end

--- Construct a new TestRunner
function TestRunner.new(tests)
	local self = setmetatable({
		tests = assert(type(tests) == "table" and tests);
		testNames = {};
		ran = false;
		passed = 0;
		failed = 0;
		errors = {};
		retvals = {};
		printPrefix = nil;
	}, TestRunner)
	self.printFunc = function (...)
		return self:_print(...)
	end

	-- Gather all test names, then sort
	for name, _func in pairs(tests) do
		table.insert(self.testNames, name)
	end
	table.sort(self.testNames)
	
	return self
end

--- Runs the tests provided to this TestRunner (can only be done once)
function TestRunner:run()
	assert(not self.ran, "Tests already run")
	self.ran = true
	for _i, name in pairs(self.testNames) do
		local func = self.tests[name]
		self:_runTest(name, func)
	end
end

--- A print override
function TestRunner:_print(...)
	print(self.printPrefix or "[TestRunner]", ...)
end

--- Runs a specific test and records the results
function TestRunner:_runTest(name, func)
	self:_print(("\t=== %s ==="):format(name))
	-- Override print inthe test function
	--getfenv(func).print = self.printFunc
	-- Reset the print flag
	local retvals = {xpcall(func, function (err)
		self:_print(debug.traceback(err, 2))
	end)}
	if table.remove(retvals, 1) then
		self:_print("Pass")
		self.passed = self.passed + 1
		self.retvals[name] = retvals
	else
		self.failed = self.failed + 1
		--self.errors[name] = retvals[1]
		self:_print("Fail") --\t" .. self.errors[name])
	end
end

--- Reports the results of the tests ran by this TestRunner
function TestRunner:report()
	assert(self.ran, "Tests not run")
	self:_print("\t====== RESULTS ======")
	if self.passed > 0 then
		self:_print(("%d tests passed"):format(self.passed))
	end
	if self.failed > 0 then
		self:_print(("%d tests failed"):format(self.failed))
	end
end

--- Run tests and report results
function TestRunner:runAndReport()
	self:run()
	self:report()
end

return TestRunner
