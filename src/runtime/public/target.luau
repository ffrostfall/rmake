local rbxl = require("./rbxl")

export type Target = {
	rbxl_dependencies: { rbxl.Identity },

	rbxl_patches: {},

	constructor: (use: rbxl.Identity) -> rbxl.Identity,
}
