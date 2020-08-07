-- This Lua module is invoked by LDoc to save output
-- in JSON format, which is then used by ldoc2mkdoc

local json = require("json")

function filterEntryItem(entry, item)
	if item["params"] then
		local params = item["params"]
		local paramsList = {}
		local paramsMap = params["map"] or {}
		for k, v in pairs(params) do
			if tonumber(k) then
				paramsList[tonumber(k)] = v
			end
		end
		item["paramsList"] = paramsList
		item["paramsMap"] = paramsMap
	end
end

return {
	filter = function (t)
		for _, entry in pairs(t) do
			for __, item in pairs(entry["items"]) do
				filterEntryItem(entry, item)
			end
		end
		print(json.encode.encode(t))
	end
}