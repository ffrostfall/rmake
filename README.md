# rmake

Streamlined fully managed Rojo

Example:
```luau
local rmake = require("@rmake")

rmake.declare_place("menu", {
	sources = {
		server = "menu/server",
		client = "menu/client",
		shared = "menu/shared",
	},

	network_directories = { "menu/net", "Packages" },
	asset_directories = { "meow" },

	builder = function(ctx: rmake.BuilderContext)
		return ctx.built_rbxl
	end,

	project_file_path = "menu.project.json",
})
```
