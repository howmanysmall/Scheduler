# Scheduler

This is a library with alternative functions to the legacy Roblox scheduler.

## Usage

To use this module, simply require it.

## API

<details>
<summary><code>function Scheduler.Wait(Seconds)</code></summary>

Yields the current thread until the specified amount of seconds have elapsed. This uses Heartbeat to avoid using the legacy scheduler that `wait` uses.

**Parameters:**
- `Seconds` (`t:optional<t:numberMin<0>>`)
The amount of seconds the thread will be yielded for. Defaults to 0.03.

**Returns:**
`t:number`
The actual time yielded (in seconds).

</details>

<details>
<summary><code>function Scheduler.Delay(DelayTime, Function, ...)</code></summary>

Schedules a function to be executed after DelayTime seconds have passed, without yielding the current thread. This function allows multiple Lua threads to be executed in parallel from the same stack. Unlike regular `delay`, this does not use the legacy scheduler and also allows passing arguments.

**Parameters:**
- `DelayTime` (`t:numberMin<0>`)
The amount of time before the function will be executed.
- `Function` (`t:callback`)
The function you are executing.
- `[variant]`
... The optional arguments you can pass that the function will execute with.

**Returns:**
[void]

</details>

<details>
<summary><code>function Scheduler.Spawn(Function, ...)</code></summary>

Runs the specified function in a separate thread, without yielding the current thread. Unlike `spawn`, it doesn't have a delay and doesn't obscure errors like `spawn` or coroutines do. Also allows passing arguments like coroutines do.

**Parameters:**
- `Function` (`t:callback`)
The function you are executing.
- `[variant]`
... The optional arguments you can pass that the function will execute with.

**Returns:**
[void]

</details>

<details>
<summary><code>function Scheduler.AddItem(Object, Lifetime)</code></summary>

This function allows the developer to schedule the removal of the object without yielding any code. It is the suggested alternative to `Debris:AddItem`, as this doesn't use the legacy scheduler and also supports tables with a `Destroy` / `destroy` method as well as connections or tables with a `Disconnect` or `disconnect` method.

**Parameters:**
- `Object` (`t:union<t:Instance, t:table, t:RBXScriptConnection>`)
The object to be added to destroy scheduler.
- `Lifetime` (`optional<t:numberMin<0>>`)
The number of seconds before the object should be destroyed. Defaults to 10.

**Returns:**
[void]

</details>
