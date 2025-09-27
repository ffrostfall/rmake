local rbxl = require("./rbxl")

local function create_declare_target(): {
	f: (
		name: string,
		func: (
			ctx: {
				upload: (universe_id: number, place_id: number, rbxl: rbxl.Identity, auth: string) -> (),
			}
		) -> ()
	) -> (),
	targets: {},
}
	local targets = {}
	local function declare_target(
		name: string,
		func: (
			ctx: {
				upload: (universe_id: number, place_id: number, rbxl: rbxl.Identity, auth: string) -> (),
			}
		) -> ()
	)
	end

	return {
		f = declare_target,

		targets = targets,
	}
end

return create_declare_target
