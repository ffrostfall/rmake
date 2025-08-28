local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local rmake_config = require("@src/discovery/rmake_config")
local log = require("@src/util/log")

local function download_place(place_id: number)
	if _G.__MODE == "debug" then
		log.trace(`mocking place download`)
		return { body = fs.readFile("C:/Users/fall/projects/orgs/hex/rmake/tests/test_data/baseplate.rbxl"), ok = true }
	end

	local response = net.request({
		url = `https://apis.roblox.com/asset-delivery-api/v1/assetId/{place_id}`,
		headers = {
			["x-api-key"] = rmake_config.secrets().download or error("need download secret to use download_place"),
		},
	})

	local response_table = serde.decode("json", response.body)
	assert(response_table and response_table.location, "request denied")

	local response_location = response_table.location

	return net.request(response_location :: any)
end

return download_place
