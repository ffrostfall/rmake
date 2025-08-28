--stylua: ignore
--[[LINK]] local api = require("@definitions/api")
--stylua: end ignore

local ERR_STR = "how did you get here?"

local rmake = {}

function rmake.declare_place(place_name: string, place: api.Place): ()
	return error(ERR_STR) :: any
end

function rmake.declare_constant(name: string, constant: api.Constant): ()
	return error(ERR_STR) :: any
end

return rmake
