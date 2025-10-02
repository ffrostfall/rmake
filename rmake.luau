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

rmake.declare_target("meow", function(use)
	local game = use(rbxl)

	game:set_constant_value("thing", 5)

	game:add_darklua_rule("meow", 5)

	game:link_to_place(123, 1234, "auth")
end)
