# Modules

<img align="right" src="docs/Markdown-black.png">

> Seriously, another dependency loader for Roblox? &ndash;Somebody

_Modules_ is a simple dependency loader for the [Roblox engine](https://www.roblox.com). It's a single [ModuleScript](https://developer.roblox.com/en-us/api-reference/class/ModuleScript) named "Modules" which exists in [ReplicatedStorage](https://developer.roblox.com/en-us/api-reference/class/ReplicatedStorage), and it is designed to replace the built-in `require` function.

## Download & Install

There's several ways you can get it:

* _[Take the Model from Roblox.com &rarr;](https://www.roblox.com/library/5517888456/Modules-v1-0-0)_
* _[Download from the GitHub releases page &rarr;](https://github.com/Ozzypig/Modules/releases/)_
* Advanced: build _Modules_ from source using [Rojo 0.5.x](https://github.com/Roblox/rojo)

Once available, insert the Model into your Roblox place, then move the root "Modules" ModuleScript into ReplicatedStorage.

## Usage

Replace `require` with the value returned by the "Modules" (the root ModuleScript). It behaves exactly the same way it did before, but in addition to typical arguments types, you can provide strings:

```lua
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"))

local MyClass = require("MyLibrary:MyClass")
local AnotherClass = require("MyLibrary:Something.AnotherClass")
```

The ModuleLoader looks for a **namespace** [Folder](https://developer.roblox.com/en-us/api-reference/class/Folder) named "MyLibrary" in either [ReplicatedStorage](https://developer.roblox.com/en-us/api-reference/class/ReplicatedStorage) or [ServerScriptService](https://developer.roblox.com/en-us/api-reference/class/ServerScriptService) (if on the server) which contains a ModuleScript named "MyClass".

## Some Batteries Included

There's a few patterns that are used pretty often in Roblox projects, so they're included as modules. They may be required by not specifying a namespace, eg `require("Event")`. The included modules are:

- `class`: provides utility functions for working with idomatic Lua classes
- `Event`: class similar to Roblox's built-in [RBXScriptSignal](https://developer.roblox.com/en-us/api-reference/datatype/RBXScriptSignal), it allows any kind of data and has `connect`, `fire`, `wait` methods
- `Maid`: class for deconstructing/deallocating objects; call `addTask` with a connection, function, Instance or other Maid to be disconnected, called or [destroyed](https://developer.roblox.com/en-us/api-reference/function/Instance/Destroy) when `cleanup` is called
- `StateMachine`: a simple implementation of a state machine pattern, event-based or subclass based
	- `StateMachine.State`: a single state in a StateMachine

## Development of _Modules_

This section is for development of _Modules_ itself, not using it to make your own stuff. To learn how to do that, check out the documentation site. The rest of this readme will only pertain to developing _Modules_.

  * To **build** and **test** this project, you need [Rojo 0.5.x](https://github.com/Roblox/rojo) and ideally [GNU Make](https://www.gnu.org/software/make/).

### Building

The [Makefile](Makefile) contains a `build` target, which creates the file Modules.rbxlx.

```sh
# Build Modules.rbxlx
$ make build
# In a new place in Roblox Studio, insert this Model into ReplicatedStorage.
# Start syncing build resources using Rojo
$ rojo serve default.project.json
```

Using [build.project.json](build.project.json), invoke Rojo to build `Modules.rbxmx`, a Roblox model file containing only the root ModuleScript (Modules). After it is built and inserted into a Roblox place, you can use the [default.project.json](default.project.json) Rojo project file to sync changes into the already-installed instance.

### Documentation

To build the documentation for this project, you need [Lua 5.1](https://lua.org) and [LDoc](https://github.com/stevedonovan/LDoc) (both of these available in [Lua for Windows](https://github.com/rjpcomputing/luaforwindows)); additionally [Python 3.7](https://www.python.org/) and the libraries in [requirements-docs.txt](requirements-docs.txt), which can be installed easily using [pip](https://pip.pypa.io/en/stable/).

On a Debian-based operating system, like Ubuntu, you can perhaps use these shell commands to install all the required dependencies:

```sh
$ sudo apt update
# Install Lua 5.1, LuaRocks, LuaJson and LDoc
$ sudo apt install lua5.1
$ sudo apt install luarocks
$ sudo luarocks install luajson
$ sudo luarocks install ldoc
# First install Python 3.7. You may have to add the deadsnakes ppa to do this:
$ sudo apt install software-properties-common
$ sudo add-apt-repository ppa:deadsnakes/ppa
$ sudo apt install python3.7
$ sudo apt install python3.7-venv
# Now create the virtual environment, activate it, and install Python dependencies
$ python3.7 -m venv venv
$ source venv/bin/activate
$ pip install -r requirements-docs.txt
# At this point you're good to go!
$ make docs
# Static HTML becomes available in site/
```

The source for _Modules_ documentation exists right in its [source code](src/) using doc comments, as well as the [docs](docs/) directory. To prepare this for the web, a somewhat roundabout process is taken to building the static web content. The [Makefile](Makefile) contains a `docs` target, which will do the following:

* Using [LDoc](https://github.com/stevedonovan/LDoc) (Lua 5.1), doc comment data is exported in a raw JSON format. The [docs.lua](docs.lua) script helps with this process by providing a filter function.
* The [ldoc2mkdoc](ldoc2mkdoc/) Python module in this repostory converts the raw JSON to Markdown using the [Jinja2](https://palletsprojects.com/p/jinja/) template engine.
* This Markdown is then passed to [MkDocs](https://www.mkdocs.org/) to build the static website source (HTML).

### Testing

The [Makefile](Makefile) contains a `test` target. It invokes [Rojo 0.5.x](https://github.com/Roblox/rojo) with the [test.project.json](test.project.json) file to build a Roblox place file, test.rbxlx, that runs all tests in Roblox Studio.

```sh
# Build test.rbxlx
$ make test
# Start syncing test resources using Rojo
$ rojo serve test.project.json
```

Tests are included in ".test" modules as children of the module they contain tests for. Tests are run using the [TestRunner](test/ReplicatedStorage/TestRunner.lua), which is invoked by [RunTests.server.lua](test/ServerScriptService/ModulesTest/RunTests.server.lua) in "ModuleTests" in ServerScriptService. The TestRunner gathers tests from every ModuleScript whose name ends with ".test". Client tests are run by [RunTests.client.lua](test/StarterPlayer/StarterPlayerScripts/RunTests.client.lua), in [StarterPlayerScripts](https://developer.roblox.com/en-us/api-reference/class/StarterPlayerScripts).

## License

_Modules_ is released under the MIT License, which you can read the complete text in [LICENSE.txt](LICENSE.txt). This means you can use this for commercial purposes, distribute it freely, modify it, and use it privately.
