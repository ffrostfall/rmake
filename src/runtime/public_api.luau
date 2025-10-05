local api = require("@definitions/api")

local public_api = {}
local metatable = { __index = public_api }
export type Identity = setmetatable<{
	rbxls: { [string]: api.RbxlConfig },

	options: { [string]: string },
}, typeof(metatable)>

local function constructor(passed_options: { [string]: string }): Identity
	local self = setmetatable({
		rbxls = {},

		options = passed_options,
	}, metatable)

	return self
end

function public_api.get_option(self: Identity, name: string): string?
	return self.options[name]
end

function public_api.index_config(self: Identity, rbxl_name: string): api.RbxlConfig
	return self.rbxls[rbxl_name]
end

local function encode() end

function public_api.create_table(self: Identity)
	return {
		define_option = function(name: string)
			return self:get_option(name)
		end,
		define_rbxl = function(name: string, config: api.RbxlConfig)
			self.rbxls[name] = config
		end,
	}
end

return { new = constructor }
