local class = require(script.Parent)


-- A simple, idiomatic Lua class
local MyClass = {}
MyClass.name = "MyClass"
MyClass.__index = MyClass

function MyClass.new()
	return setmetatable({name = "MyClass(object)"}, MyClass)
end

-- A simple, idiomatic Lua subclass
local MySubclass = setmetatable({}, MyClass)
MySubclass.name = "MySubclass"
MySubclass.__index = MySubclass

function MySubclass.new()
	local self = setmetatable(MyClass.new(), MySubclass)
	self.name = "MySubclass(object)"
	return self
end

-- Yet another class
local MyOtherClass = {}
MyOtherClass.name = "MyOtherClass"
MyOtherClass.__index = MyOtherClass

function MyOtherClass.new()
	return setmetatable({name = "MyOtherClass"}, MyOtherClass)
end

-- Begin tests

local classTests = {}

classTests["test_class.classOf"] = function ()
	local myClassObject = MyClass.new()
	local myOtherClassObject = MyOtherClass.new()
	local mySubclassObject = MySubclass.new()

	assert(class.classOf(myClassObject)      == MyClass)
	assert(class.classOf(myOtherClassObject) == MyOtherClass)
	assert(class.classOf(mySubclassObject)   == MySubclass)
end

classTests["test_class.getSuperclass"] = function ()
	assert(class.getSuperclass(MySubclass) == MyClass)
	assert(type(class.getSuperclass(MyClass)) == "nil")
	assert(type(class.getSuperclass(MyOtherClass)) == "nil")
end

classTests["test_class.extends"] = function ()
	local myClassObject = MyClass.new()
	local myOtherClassObject = MyOtherClass.new()
	local mySubclassObject = MySubclass.new()

	assert(    class.extends(MySubclass, MyClass))
	assert(not class.extends(MyClass, MyOtherClass))
end

classTests["test_class.instanceOf"] = function ()
	local myClassObject = MyClass.new()
	local myOtherClassObject = MyOtherClass.new()
	local mySubclassObject = MySubclass.new()

	assert(    class.instanceOf(myClassObject, MyClass))
	assert(    class.instanceOf(mySubclassObject, MyClass))
	assert(not class.instanceOf(myOtherClassObject, MyClass))
	assert(not class.instanceOf(myClassObject, MyOtherClass))
	assert(not class.instanceOf(mySubclassObject, MyOtherClass))
end

return classTests
