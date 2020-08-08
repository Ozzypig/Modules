--[[-- Implementation of Roblox's event API using a @{rbx:class/BindableEvent|BindableEvent}.
Event re-implements Roblox's event API (connect, fire, wait) by wrapping a
@{rbx:class/BindableEvent|BindableEvent}.

This Event implementation is based on the [Signal from Nevermore Engine by
Quenty](https://github.com/Quenty/NevermoreEngine/blob/version2/Modules/Shared/Events/Signal.lua).

#### Why?

This implementation does not suffer from the restrictions normally introduced by using
a BindableEvent. When firing a BindableEvent, the Roblox engine makes a copy of the values
passed to @{rbx:function/BindableEvent/Fire|BindableEvent:Fire}. On the other hand, this class
temporarily stores the values passed to @{Event:fire|fire}, fires the wrapped BindableEvent
without arguments. The values are then retrieved and passed appropriately.

This means that the _exact_ same values passed to @{Event:fire|fire} are
sent to @{Event:connect|connected} handler functions and also returned by @{Event:wait|wait},
rather than copies. This includes tables with metatables, and other values that are normally
not serializable by Roblox.

#### Usage
```lua
local zoneCapturedEvent = Event.new()

-- Hook up a handler function using connect
local function onZoneCaptured(teamName)
	print("The zone was captured by: " .. teamName)
end
zoneCapturedEvent:connect(onZoneCaptured)

-- Or use wait, if you like that sort of thing
local teamName
while true do
	teamName = zoneCapturedEvent:wait()
	print("The zone was captured by: " .. teamName)
end

-- Trigger the event using fire
zoneCapturedEvent:fire("Blue team")
zoneCapturedEvent:fire("Red team")

-- Remember to call cleanup then forget about the event when
-- it is no longer needed!
zoneCapturedEvent:cleanup()
zoneCapturedEvent = nil
```
]]
-- @classmod Event

local Event = {}
Event.__index = Event
Event.ClassName = "Event"

--- Constructs a new Event.
-- @staticfunction Event.new
-- @constructor
-- @treturn Event
function Event.new()
	local self = setmetatable({}, Event)

	self._bindableEvent = Instance.new("BindableEvent")
	self._argData = nil
	self._argCount = nil -- Prevent edge case of :Fire("A", nil) --> "A" instead of "A", nil

	return self
end

--- Connect a new handler function to the event. Returns a connection object that can be disconnected.
-- @tparam function handler Function handler called with arguments passed when `:Fire(...)` is called
-- @treturn rbx:datatype/RBXScriptConnection Connection object that can be disconnected
function Event:connect(handler)
	if not (type(handler) == "function") then
		error(("connect(%s)"):format(typeof(handler)), 2)
	end

	return self._bindableEvent.Event:Connect(function()
		handler(unpack(self._argData, 1, self._argCount))
	end)
end

--- Wait for @{Event:fire|fire} to be called, then return the arguments it was given.
-- @treturn ... Variable arguments from connection
function Event:wait()
	self._bindableEvent.Event:Wait()
	assert(self._argData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
	return unpack(self._argData, 1, self._argCount)
end

--- Fire the event with the given arguments. All handlers will be invoked. Handlers follow
-- Roblox Event conventions.
-- @param ... Variable arguments to pass to handler
function Event:fire(...)
	self._argData = {...}
	self._argCount = select("#", ...)
	self._bindableEvent:Fire()
	self._argData = nil
	self._argCount = nil
end

--- Disconnects all connected events to the Event. Voids the Event as unusable.
function Event:cleanup()
	if self._bindableEvent then
		self._bindableEvent:Destroy()
		self._bindableEvent = nil
	end

	self._argData = nil
	self._argCount = nil
end

-- Aliases
Event.Wait = Event.wait
Event.Fire = Event.fire
Event.Connect = Event.connect
Event.Destroy = Event.cleanup

return Event