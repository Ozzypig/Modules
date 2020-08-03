# Modules

> Seriously, another dependency loader for Roblox? &ndash;Somebody

**Modules** is a simple dependency loader for the [Roblox engine](https://www.roblox.com). It's a single [ModuleScript](https://developer.roblox.com/en-us/api-reference/class/ModuleScript) named "Modules" which exists in [ReplicatedStorage](https://developer.roblox.com/en-us/api-reference/class/ReplicatedStorage), and it is designed to replace the built-in `require` function.

## Usage

Replace `require` with the value returned by the "Modules" (the root ModuleScript). It behaves exactly the same way it did before, but in addition to typical arguments types, you allow you to provide strings:

```lua
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"))

local MyClass = require("MyLibrary:MyClass")
local AnotherClass = require("MyLibrary:Something.AnotherClass")
```

The ModuleLoader looks for a **namespace** [Folder](https://developer.roblox.com/en-us/api-reference/class/Folder) named "MyLibrary" in either [ReplicatedStorage](https://developer.roblox.com/en-us/api-reference/class/ReplicatedStorage) or [ServerScriptService](https://developer.roblox.com/en-us/api-reference/class/ServerScriptService) (if on the server) which contains a ModuleScript named "MyClass".

The second call to require does something similar, although it looks for any object called "Something", followed by a ModuleScript called "AnotherClass". It is similar to indexing a child in a Roblox object using the dot operator (eg `workspace.Part`).

Both ReplicatedStorage and ServerScriptService may contain namespace folders of the same name to separate shared modules and server-only modules. A namespace folder within ServerScriptService may also contain a "Replicated" folder, which will automatically be replicated to the client as if it were in ReplicatedStorage.

## Some Batteries Included

There's a few patterns that are used pretty often in Roblox projects, so they're included as modules. They may be required by not specifying a namespace, eg `require("Event")`. The included modules are:

- `class`: provides utility functions for working with idomatic Lua classes
- `Event`: class similar to Roblox's built-in [RBXScriptSignal](https://developer.roblox.com/en-us/api-reference/datatype/RBXScriptSignal), it allows any kind of data and has `connect`, `fire`, `wait` methods
- `Maid`: class for deconstructing/deallocating objects; call `addTask` with a connection, function, Instance or other Maid to be disconnected, called or [destroyed](https://developer.roblox.com/en-us/api-reference/function/Instance/Destroy) when `cleanup` is called
- `StateMachine`: a simple implementation of a state machine pattern, event-based or subclass based
	- `StateMachine.State`: a single state in a StateMachine

## Testing

The [Makefile](Makefile) contains a `test` target. It uses Rojo to build a Roblox place file (test.rblx) that runs all tests.

```bash
# Build test.rbxlx
$ make test
# Start syncing test resources using Rojo
$ rojo serve test.project.json
```

Tests are included in ".test" modules as children of the module they contain tests for, such as [Modules.test](src/Modules.test/init.lua), except for client tests which are in [ClientTests/Modules.test.lua](test/StarterPlayer/StarterPlayerScripts/ClientTests/Modules.test.lua)

Tests are run using the [TestRunner](test/ReplicatedStorage/TestRunner.lua), which invoked by[RunTests.server.lua](test/ServerScriptService/ModulesTest/RunTests.server.lua) in "ModuleTests" in ServerScriptService, which gathers tests from every ModuleScripts whose name ends with ".test". For client tests, they are invoked by [RunTests.client.lua](test/StarterPlayer/StarterPlayerScripts/RunTests.client.lua), in [StarterPlayerScripts](https://developer.roblox.com/en-us/api-reference/class/StarterPlayerScripts).

## Building

The [Makefile](Makefile) contains a `build` target.

```bash
# Build Modules.rbxlx
$ make build
# Start syncing build resources using Rojo
$ rojo serve default.project.json
```

Using [build.project.json](build.project.json), invoke Rojo to build `Modules.rbxmx`, which is a Roblox model file containing only the root ModuleScript (Modules).
