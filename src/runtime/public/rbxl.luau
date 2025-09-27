local api = require("@definitions/api")

local rbxl = {}
local metatable = { __index = rbxl }
export type Identity = setmetatable<{
	config: api.RbxlConfig,
	user_added_rules: { api.DarkluaRule },
	constants: { [string]: string },
}, typeof(metatable)>

local function constructor(config: api.RbxlConfig): Identity
	local self = setmetatable({
		config = config,
		user_added_rules = {},
		constants = {},
	}, metatable)

	return self
end

function rbxl.add_darklua_rule(self: Identity, rule: api.DarkluaRule) end

function rbxl.set_constant_value(self: Identity, constant: string, value: any) end

return { new = constructor }
