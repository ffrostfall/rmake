local rmake = require("@rmake")

local rbxl = rmake.declare_rbxl({ ... })

rmake.declare_target("production", {
	rbxl.g,
})
