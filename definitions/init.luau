--stylua: ignore
--[[LINK]] local api = require("@definitions/api")
--stylua: end ignore

local ERR_STR = "how did you get here?"

local rmake = {}

function rmake.define_rbxl(name: string, config: api.RbxlConfig)
	return error(ERR_STR)
end

function rmake.define_option(identifier: string): string?
	return error(ERR_STR)
end

return rmake
