--[[- Utility object for cleaning up, destroying and otherwising releasing resources.
A **Maid** is provided tasks which it will handle when it is told to @{Maid:cleanup|cleanup}.
A task may be a function, connection, Roblox Instance, or table with a `cleanup` function.
Connections are always disconnected before other tasks.

This Maid implementation is based on the
[Maid from Nevermore Engine by Quenty](https://github.com/Quenty/NevermoreEngine/blob/version2/Modules/Shared/Events/Maid.lua).

#### Usage

```lua
local maid = Maid.new()

-- Something you might need to clean up:
local part = workspace.SomePart

-- Add tasks to the maid. A task can be...
maid:addTask(part)                      -- a Roblox instance
maid:addTask(part.Touched:Connect(...)) -- a connection
maid:addTask(function() ... end)        -- a function
maid:addTask(Event.new())               -- something with a cleanup function

-- You can add tasks by id:
maid["somePart"] = Instance.new("Part") -- "somePart" is a task id
maid["somePart"] = Instance.new("Part") -- the first part gets cleaned up
                                        -- because "somePart" got overwritten!

-- Instruct the maid to perform all tasks:
maid:cleanup()
```
]]
-- @classmod Maid

local Maid = {}
--Maid.__index = Maid

--- Constructs a new Maid.
-- @constructor
-- @treturn Maid
function Maid.new()
	local self = setmetatable({

		--- Stores this maid's tasks
		-- @field Maid.tasks
		-- @treturn table
		tasks = {};

	}, Maid)
	return self
end

function Maid:__index(index)
	if Maid[index] then
		return Maid[index]
	else
		return self.tasks[index]
	end
end

function Maid:__newindex(index, newTask)
	if type(Maid[index]) ~= "nil" then
		error(("\"%s\" is reserved"):format(tostring(index)), 2)
	end 
	local oldTask = self.tasks[index]
	self.tasks[index] = newTask
	if oldTask then self:performTask(oldTask) end
end

--- Executes the given task
function Maid:performTask(task)
	local ty = typeof(task)
	if ty == "function" then
		task()
	elseif ty == "Instance" then
		task:Destroy()
	elseif ty == "RBXScriptConnection" then
		task:disconnect()
	elseif task.cleanup then
		task:cleanup()
	else
		error(("unknown task type \"%s\""):format(ty))
	end
end

--- Give this maid a task, and returns its id.
-- @treturn number the task id
function Maid:addTask(task)
	assert(task, "Task expected")
	local taskId = #self.tasks + 1
	self[taskId] = task
	return taskId
end
Maid.giveTask = Maid.addTask

--- Cause the maid to do all of its tasks then forget about them
function Maid:cleanup()
	local tasks = self.tasks
	
	-- Disconnect first
	for index, task in pairs(tasks) do
		if typeof(task) == "RBXScriptConnection" then
			tasks[index] = nil
			task:disconnect()
		end
	end
	
	-- Clear tasks table (don't use generic for here)
	local index, task = next(tasks)
	while type(task) ~= "nil" do
		self:performTask(task)
		tasks[index] = nil
		index, task = next(tasks)
	end
end

return Maid