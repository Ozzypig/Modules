--- Maid class based on Maid from Nevermore engine by Quenty
-- @classmod Maid

local Maid = {}
--Maid.__index = Maid

function Maid.new()
	local self = setmetatable({
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

function Maid:giveTask(task)
	assert(task)
	local taskId = #self.tasks + 1
	self[taskId] = task
	return taskId
end
Maid.addTask = Maid.giveTask

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