--- Tests for class module
--@module class.test

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local class = require(Modules:WaitForChild("class"))

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

	assert(class.classOf(myClassObject)      == MyClass, "class.classOf should identify class of basic object")
	assert(class.classOf(myOtherClassObject) == MyOtherClass, "class.classOf should identify class of basic object")
	assert(class.classOf(mySubclassObject)   == MySubclass, "class.classOf should respect subclass relationship")
end

classTests["test_class.getSuperclass"] = function ()
	assert(class.getSuperclass(MySubclass) == MyClass, "class.getSuperclass should respect subclass relationship")
	assert(type(class.getSuperclass(MyClass)) == "nil", "class.getSuperclass should return nil when there is no superclass")
	assert(type(class.getSuperclass(MyOtherClass)) == "nil", "class.getSuperclass should return nil when there is no superclass")
end

classTests["test_class.extends"] = function ()
	assert(    class.extends(MySubclass, MyClass), "class.extends should respect subclass relationship")
	assert(not class.extends(MyClass, MyOtherClass), "class.extends should respect subclass relationship in correct direction")
end

classTests["test_class.instanceOf"] = function ()
	local myClassObject = MyClass.new()
	local myOtherClassObject = MyOtherClass.new()
	local mySubclassObject = MySubclass.new()

	assert(    class.instanceOf(myClassObject, MyClass), "class.instanceOf should identify class of basic object")
	assert(    class.instanceOf(mySubclassObject, MyClass), "class.instanceOf should respect subclass relationship")
	assert(not class.instanceOf(myOtherClassObject, MyClass), "class.instanceOf should return false if the object is not an instance of the class")
	assert(not class.instanceOf(myClassObject, MyOtherClass), "class.instanceOf should return false if the object is not an instance of the class")
	assert(not class.instanceOf(mySubclassObject, MyOtherClass), "class.instanceOf should return false if the object is not an instance of the class")
end

return classTests
