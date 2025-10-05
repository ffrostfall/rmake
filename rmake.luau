local rmake = require("@rmake")
local fs = require("@lune/fs")

local value = rmake.define_option("SomeFlagThing")

rmake.define_rbxl("game", {
	constants = {
		["RELEASE_MODE"] = {
			type = `"release" | "debug"`,
			value = value,
		},
	},
})
