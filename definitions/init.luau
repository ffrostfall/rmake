--stylua: ignore
--[[LINK]] local api = require("@definitions/api")
--stylua: end ignore

type RbxlMetatable = {
	set_constant_value: (self: Rbxl, constant: string, value: unknown) -> (),
	add_darklua_rule: (self: Rbxl, rule: api.DarkluaRule) -> (),
}

type Rbxl = setmetatable<{}, {
	__index: RbxlMetatable,
}>

export type TargetContext = {
	upload_rbxl: (universe_id: number, place_id: number, rbxl: Rbxl, auth: string) -> (),
}

local ERR_STR = "how did you get here?"

local rmake = {}

function rmake.declare_target(name: string, f: (ctx: TargetContext) -> ())
	return error(ERR_STR)
end

function rmake.declare_rbxl(conf: api.RbxlConfig): Rbxl
	return error(ERR_STR)
end

return rmake
