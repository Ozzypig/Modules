# Modules

<img src="Modules-black.png" style="float:right;padding:1.25em;" alt="Modules logo">

> Seriously, another dependency loader for Roblox? &ndash;Somebody, probably

_Modules_ is a simple dependency loader for the [Roblox engine](https://www.roblox.com). It's a single [ModuleScript](https://developer.roblox.com/en-us/api-reference/class/ModuleScript) named "Modules" which exists in [ReplicatedStorage](https://developer.roblox.com/en-us/api-reference/class/ReplicatedStorage), and it is designed to replace the built-in `require` function.

```lua
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"))

local MyModule = require("MyNamespace:MyModule")
```

_[Visit the Getting Started guide to learn the basics &rarr;](getting-started.md)_

## Download & Install

There's several ways you can get it:

* _[Take the Model from Roblox.com &rarr;](https://www.roblox.com/library/5618924671/Modules-v1-1-0)_
* _[Download from the GitHub releases page &rarr;](https://github.com/Ozzypig/Modules/releases/)_
* Advanced: build _Modules_ from source using [Rojo 0.5.x](https://github.com/Roblox/rojo)

Once available, insert the Model into your Roblox place, then move the root "Modules" ModuleScript into ReplicatedStorage.

## Structure

_Modules_ also includes some super common patterns as included ModuleScripts. Check out the structure here:

<pre><code class="nohighlight">&boxur; ReplicatedStorage
  &boxur; <a href="api/ModuleLoader">Modules</a>           &larr; This is the <strong>root</strong> ModuleScript
    &boxvr; <a href="api/Event">Event</a>
    &boxvr; <a href="api/Maid">Maid</a>
    &boxvr; <a href="api/StateMachine">StateMachine</a>
    &boxv; &boxur; <a href="api/State">State</a>
    &boxur; <a href="api/class">class</a>
</code></pre>

Each of these can be required by simply providing its name without a namespace. For example:

```lua
local Event = require("Event")
local State = require("StateMachine.State")
```
