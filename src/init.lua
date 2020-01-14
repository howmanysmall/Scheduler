local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local Table = Resources:LoadLibrary("Table")
local t = Resources:LoadLibrary("t")

local Heartbeat = RunService.Heartbeat

local NonNegativeNumber = t.numberMin(0)
local OptionalNonNegativeNumber = t.optional(NonNegativeNumber)

local DelayTuple = t.tuple(NonNegativeNumber, t.callback)
local AddItemTuple = t.tuple(
	t.union(t.Instance, t.table, t.RBXScriptConnection),
	OptionalNonNegativeNumber
)

local Scheduler = {}

--[[**
	Yields the current thread until the specified amount of seconds have elapsed. This uses Heartbeat to avoid using the legacy scheduler.

	@param [t:optional<t:numberMin<0>>] Seconds The amount of seconds the thread will be yielded for. Defaults to 0.03.
	@returns [t:number] The actual time yielded (in seconds).
**--]]
function Scheduler.Wait(Seconds)
	assert(OptionalNonNegativeNumber(Seconds))
	Seconds = Seconds or 0.03
	Seconds = Seconds < 0 and 0 or Seconds
	local TimeRemaining = Seconds

	while TimeRemaining > 0 do
		TimeRemaining = TimeRemaining - Heartbeat:Wait()
	end

	return Seconds - TimeRemaining
end

local Scheduler_Wait = Scheduler.Wait

--[[**
	Schedules a function to be executed after DelayTime seconds have passed, without yielding the current thread. This function allows multiple Lua threads to be executed in parallel from the same stack. Unlike regular delay, this does not use the legacy scheduler and also allows passing arguments.

	@param [t:numberMin<0>] DelayTime The amount of time before the function will be executed.
	@param [t:callback] Function The function you are executing.
	@param [variant] ... The optional arguments you can pass that the function will execute with.
	@returns [void]
**--]]
function Scheduler.Delay(DelayTime, Function, ...)
	assert(DelayTuple(DelayTime, Function))
	local Arguments = table.pack(...)
	local DelayEvent = Instance.new("BindableEvent")

	DelayEvent.Event:Connect(function()
		Scheduler_Wait(DelayTime)
		Function(table.unpack(Arguments, 1, Arguments.n))
		DelayEvent:Destroy()
	end)

	DelayEvent:Fire()
end

--[[**
	Runs the specified function in a separate thread, without yielding the current thread. Unlike spawn, it doesn't have a delay and doesn't obscure errors like spawn or coroutines do. Also allows passing arguments like coroutines do.

	@param [t:callback] Function The function you are executing.
	@param [variant] ... The optional arguments you can pass that the function will execute with.
	@returns [void]
**--]]
function Scheduler.Spawn(Function, ...)
	assert(t.callback(Function))
	local Arguments = table.pack(...)
	local SpawnEvent = Instance.new("BindableEvent")

	SpawnEvent.Event:Connect(function()
		Function(table.unpack(Arguments, 1, Arguments.n))
	end)

	SpawnEvent:Fire()
	SpawnEvent:Destroy()
end

--[[**
	This function allows the developer to schedule the removal of the object without yielding any code. It is the suggested alternative to Debris:AddItem, as this doesn't use the legacy scheduler and also supports tables with a Destroy / destroy method.

	@param [t:union<t:Instance, t:table, t:RBXScriptConnection>] Object The object to be added to destroy scheduler.
	@param [t:optional<t:numberMin<0>>] Lifetime The number of seconds before the object should be destroyed. Defaults to 10.
	@returns [void]
**--]]
function Scheduler.AddItem(Object, Lifetime)
	assert(AddItemTuple(Object, Lifetime))
	local DebrisEvent = Instance.new("BindableEvent")

	DebrisEvent.Event:Connect(function()
		Scheduler_Wait(Lifetime or 10)
		if Object then
			if Object.Destroy then
				pcall(Object.Destroy, Object)
			elseif Object.destroy then
				pcall(Object.destroy, Object)
			elseif Object.Disconnect then
				pcall(Object.Disconnect, Object)
			elseif Object.disconnect then
				pcall(Object.disconnect, Object)
			end
		end

		DebrisEvent:Destroy()
	end)

	DebrisEvent:Fire()
end

return Table.Lock(Scheduler)