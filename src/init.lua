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
	t.union(t.Instance, t.table, t.RBXScriptConnection, t.userdata),
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
	Seconds = math.max(Seconds or 0.03, 0)
	local TimeRemaining = Seconds

	while TimeRemaining > 0 do
		TimeRemaining -= Heartbeat:Wait()
	end

	return Seconds - TimeRemaining
end

--[[**
	Schedules a function to be executed after DelayTime seconds have passed, without yielding the current thread. This function allows multiple Lua threads to be executed in parallel from the same stack. Unlike regular delay, this does not use the legacy scheduler and also allows passing arguments.

	@param [t:numberMin<0>] DelayTime The amount of time before the function will be executed.
	@param [t:callback] Function The function you are executing.
	@param [variant] ... The optional arguments you can pass that the function will execute with.
	@returns [t:RBXScriptConnection] The connection that can be disconnected if you wish to cancel execution.
**--]]
function Scheduler.Delay(DelayTime, Function, ...)
	assert(DelayTuple(DelayTime, Function))
	local Length = select("#", ...)
	if Length > 0 then
		local Arguments = {...}
		local ExecuteTime = tick() + DelayTime
		local Connection

		Connection = Heartbeat:Connect(function()
			if tick() >= ExecuteTime then
				Connection:Disconnect()
				Function(table.unpack(Arguments, 1, Length))
			end
		end)

		return Connection
	else
		local ExecuteTime = tick() + DelayTime
		local Connection

		Connection = Heartbeat:Connect(function()
			if tick() >= ExecuteTime then
				Connection:Disconnect()
				Function()
			end
		end)

		return Connection
	end
end

-- @source https://devforum.roblox.com/t/psa-you-can-get-errors-and-stack-traces-from-coroutines/455510/2
local function Finish(Thread, Success, ...)
	if not Success then
		warn(debug.traceback(Thread, "Something went wrong!\n" .. tostring((...))))
	end

	return Success, ...
end

--[[**
	Runs the specified function in a separate thread, without yielding the current thread. Unlike spawn, it doesn't have a delay and doesn't obscure errors like spawn or coroutines do. Also allows passing arguments like coroutines do.

	@param [t:callback] Function The function you are executing.
	@param [variant] ... The optional arguments you can pass that the function will execute with.
	@returns [t:tuple<t:boolean, t:any>] Whether or not the execution was successful, and whatever the function might've returned with (error message, return values, etc).
**--]]
function Scheduler.Spawn(Function, ...)
	assert(t.callback(Function))
	local Thread = coroutine.create(Function)
	return Finish(Thread, coroutine.resume(Thread, ...))
end

--[[**
	Runs the specified function in a separate thread, without yielding the current thread. This doesn't obscure errors like spawn or coroutines do, but it does share the similar small delay that spawn has. Also allows passing arguments like coroutines do.

	@param [t:callback] Function The function you are executing.
	@param [variant] ... The optional arguments you can pass that the function will execute with.
	@returns [void]
**--]]
function Scheduler.SpawnDelayed(Function, ...)
	assert(t.callback(Function))
	local Length = select("#", ...)
	if Length > 0 then
		local Arguments = {...}
		local Connection

		Connection = Heartbeat:Connect(function()
			Connection:Disconnect()
			Function(table.unpack(Arguments, 1, Length))
		end)
	else
		local Connection

		Connection = Heartbeat:Connect(function()
			Connection:Disconnect()
			Function()
		end)
	end
end

--[[**
	This function allows the developer to schedule the removal of the object without yielding any code. It is the suggested alternative to Debris:AddItem, as this doesn't use the legacy scheduler and also supports tables with a Destroy / destroy method.

	@param [t:union<t:Instance, t:table, t:RBXScriptConnection, t:userdata>] Object The object to be added to destroy scheduler.
	@param [t:optional<t:numberMin<0>>] Lifetime The number of seconds before the object should be destroyed. Defaults to 10.
	@returns [t:RBXScriptConnection] The connection that can be disconnected if you wish to cancel execution.
**--]]
function Scheduler.AddItem(Object, Lifetime)
	assert(AddItemTuple(Object, Lifetime))
	local ExecuteTime = tick() + (Lifetime or 10)
	local Connection

	Connection = Heartbeat:Connect(function()
		if tick() >= ExecuteTime then
			Connection:Disconnect()
			if Object then
				local TypeOf = typeof(Object)
				if TypeOf == "Instance" then
					pcall(Object.Destroy, Object)
				elseif TypeOf == "RBXScriptConnection" then
					pcall(Object.Disconnect, Object)
				else
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
			end
		end
	end)

	return Connection
end

return Table.Lock(Scheduler)
