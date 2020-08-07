--- Implementation of Roblox's event API using a BindableEvent.
-- Event re-implements Roblox's event API (connect, fire, wait) using a BindableEvent,
-- but without restrictions. The exact same values passed to @{Event:fire|fire} are
-- sent to @{Event:connect|connected} functions and returned by @{Event:wait|wait},
-- rather than copies, including tables with metatables.
--
-- This class is based on Signal in Nevermore by Quenty.
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