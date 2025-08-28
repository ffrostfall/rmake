local rmake_config = require("@src/discovery/rmake_config")
local global_types = require("@src/global_types")

local UPLOAD_ENDPOINT = "https://apis.roblox.com/universes/v1/%*/places/%*/versions?versionType=Published"

local net_requests = {}

function net_requests.upload_place(universe_id: number, place_id: number, binary: string): global_types.NetworkCall
	return {
		kind = "NetworkCall",

		params = {
			url = string.format(UPLOAD_ENDPOINT :: any, tostring(universe_id), tostring(place_id)),

			headers = {
				["Content-Type"] = "application/octet-stream",
				["x-api-key"] = rmake_config.secrets().upload or error("need upload secret to use push"),
			},

			body = binary,
		},
	}
end

return net_requests
