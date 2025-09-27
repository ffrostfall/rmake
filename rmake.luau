local rmake = require("@rmake")

local rbxl = rmake.declare_rbxl({
	network_declarations = {
		"net",
		"meow",
	},

	builder = function(a)
		return a.built_place
	end,

	sources = {},
	project_file = "meow",

	constants = {
		["__BUILD_MODE"] = {
			kind = "luau" :: "luau",
			type_str = '"deb" | "rel"',
			value = "test" :: any,
		},
	},
})

rmake.declare_target("meow", function(ctx)
	rbxl:set_constant_value("__BUILD_MODE", "debug")

	ctx.upload_rbxl(1, 2, rbxl, "meow")
end)
