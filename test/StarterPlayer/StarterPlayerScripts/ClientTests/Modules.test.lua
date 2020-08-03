local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"))

local ModulesClient = {}

function ModulesClient.test_version()
	assert(require("version") == require.VERSION)
end

return ModulesClient
