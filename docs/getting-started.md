# Getting Started

_Modules_ is designed to be simple and straightforward.

## 1. Install _Modules_

After inserting _Modules_ into your game, move the root "Modules" ModuleScript to ReplicatedStorage.

<pre><code class="nohighlight">game
&boxur; ReplicatedStorage
  &boxur; Modules
</code></pre>

Anywhere in ReplicatedStorage will work, but it's recommended to be a direct child.

## 2. Create Your Namespace

To make a **namespace**, create a Folder in [ServerScriptService](https://developer.roblox.com/en-us/api-reference/class/ServerScriptService) and/or [ReplicatedStorage](https://developer.roblox.com/en-us/api-reference/class/ReplicatedStorage). The Name of this folder should be distinct like any other object in the hierarchy, and ideally shouldn't contain symbols.

<pre><code class="nohighlight">game
&boxvr; ReplicatedStorage
&boxv; &boxur; MyGame         &larr; Create this Folder (for client stuff)...
&boxur; ServerScriptService
  &boxur; MyGame         &larr; ...and/or this folder (for server stuff)
</code></pre>

It's recommended you use [Pascal case](https://en.wikipedia.org/wiki/Pascal_case) for the name of your namespace. Examples: `MyLibrary`, `SomeOtherLibrary`, etc

## 3. Add ModuleScripts, and Everything Else

Add whatever ModuleScripts to your namespace folder you like. As with the namespace folder, you should follow a consistent naming scheme for your modules. Avoid non-alphanumeric characters. If a module needs assets, you can include those within it or somewhere else in your namespace folder.

Consider the following heirarchy, where the contents of `Tools` are ModuleScripts:

<pre><code class="nohighlight">game
&boxvr; ReplicatedStorage
&boxv; &boxvr; Modules
&boxv; &boxur; MyGame [Folder]
&boxv;   &boxur; Tools [Folder]
&boxv;     &boxvr; Sword
&boxv;     &boxvr; Slingshot
&boxv;     &boxur; Rocket Launcher
&boxur; ServerScriptService
  &boxur; MyGame [Folder]
    &boxur; ServerManager
</code></pre>

## 4. Require Your ModuleScripts

A string passed to `require` should first specify a namespace, followed by a colon, then the module. If the Module is within other objects, separate their names with a period. Using the heirarchy above, from (3):

```lua
-- Some script in your game:
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"))

local ServerManager = require("MyGame:ServerManager")
local Sword =         require("MyGame:Tools.Sword")
local Slingshot =     require("MyGame:Tools.Slingshot")
```

_Modules_ uses the following process to locate the module:

1. If no namespace was specified, assume the Modules ModuleScript is the namespace.
2. Check for client module first: look for the namespace in ReplicatedStorage, if found, check it for the module.
3. Check for server modules second: look for the namespace in ServerStorage, if found, check it for the moduke. If either the namespace or module is missing, raise a "module not found" error.

If both the client and server require a shared library, but that shared library has a dependency only relevant to either the client or server, you can use `require.server` or `require.client` to skip the require and return nil if the code isn't running on that network peer:

```lua
-- Some ModuleScript that is required on both client and server
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"))

-- Client won't be able to access this
local ServerManager = require.server("MyGame:ServerManager")

local MySharedLibrary = {}

-- Perhaps in MySharedLibrary there's a function which is 
-- only called by the server, and that function might use ServerManager,
-- but we still want to enable the client to require this module for the other bits.

return MySharedLibrary
```

This is useful in a variety of cases. Most notably, if constants in a shared class module are needed by both the client and server, constructing the class might only be possible on the server. This could due to certain server dependencies, but using `require.server`, the client can skip over those dependencies since it wouldn't be constructing the object and using those dependencies.

## 5. Use a "Replicated" Folder (Optional)

In some cases, like using [Roblox Packages](https://developer.roblox.com/en-us/articles/roblox-packages), it's desirable to unify all of a namespace's code (both server and client code) into one root object. You can replicate only part of a namespace folder in ServerScriptService using a "Replicated" Folder:

For namespace Folders in ServerScriptService, you may add a Folder named "Replicated". Such a folder is automatically replicated to clients: the folder is moved to ReplicatedStorage and renamed to the same as the namespace. Therefore, any ModuleScripts inside the Replicated folder can be required as if the Module were placed in ReplicatedStorage in the first place.

Consider the following game structure, which uses both ServerScriptService and ReplicatedStorage namespace folders. To unify the codebase into one object, we can move the client folder into the server folder and rename it "Replicated".

<pre><code class="nohighlight">game
&boxvr; ReplicatedStorage
&boxv; &boxvr; Modules
&boxv; &boxur; MyNamespace          &larr; Rename this "Replicated"...
&boxv;   &boxur; SomeSharedModule
&boxur; ServerScriptService
  &boxur; MyNamespace          &larr; ...and move it into here.
    &boxur; JustAServerModule
</code></pre>

After moving the ReplicatedStorage namespace folder to the ServerScriptService folder, and renaming it to "Replicated", the structure should now look like this:

<pre><code class="nohighlight">game
&boxvr; ReplicatedStorage
&boxv; &boxur; Modules
&boxur; ServerScriptService
  &boxur; MyNamespace
    &boxvr; JustAServerModule
    &boxur; Replicated         &larr; When Modules is loaded, this is moved to:
      &boxur; SomeSharedModule   ReplicatedStorage.MyNamespace.SomeSharedModule
                                 (which is what we had before, but now there's
                                 a single root object for all of MyNamespace!)
</code></pre>

## 6. Check out the Goodies

Modules comes with a few really useful classes you should never leave home without. See [Overview#Structure](index.md#structure) for a list, or check out a few of these: [Event](api/Event.md), [Maid](api/Maid.md), [StateMachine](api/StateMachine).
