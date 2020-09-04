--- @module class
-- Utility for working with idiomatic Lua object-oriented patterns

local class = {}

--- Given an `object`, return its class
function class.classOf(object)
	return getmetatable(object)
end

--- Given an `object` and a `class`, return if that object is an instance of another class/superclass
-- Equivalent to @{class.extends}(@{class.classOf}(object), `cls`)
function class.instanceOf(object, cls)
	return class.extends(getmetatable(object), cls)
end

--- Get the superclass of a class
function class.getSuperclass(theClass)
	local meta = getmetatable(theClass)
	return meta and meta.__index
end

--- Check if one class extends another class
function class.extends(subclass, superclass)
	assert(type(subclass) == "table")
	assert(type(superclass) == "table")
	local c = subclass
	repeat
		if c == superclass then
			return true
		end

		c = class.getSuperclass(c)
	until not c
	return false
end

return class
