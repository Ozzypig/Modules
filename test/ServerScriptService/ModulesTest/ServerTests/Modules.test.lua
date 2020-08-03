local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"))

local server = {}

function server.test_version()
	assert(require("version") == require.VERSION)
end

function server.test_hello_world()
	print("Hello, server")
end

function server.test_kaboom()
	--error("Kaboom")
end

return server
