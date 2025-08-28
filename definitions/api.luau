local roblox = require("@lune/roblox")

--stylua: ignore
--[[ EXPORT ]] export type BuilderContext = {
	download_place: (place_id: number, version: number?) -> roblox.DataModel,
	built_rbxl: roblox.DataModel,
}

--stylua: ignore
--[[ EXPORT ]] export type RbxlBuilder = (ctx: BuilderContext) -> roblox.DataModel

--stylua: ignore
--[[ EXPORT ]] export type Place = {
	builder: RbxlBuilder,

	project_file_path: string,

	sources: { [string]: string },

	network_directories: { string },
	asset_directories: { string },
}

export type Constant = {
	kind: "env",

	name: string,
	type_str: string,
} | {
	kind: "luau",

	type_str: string,
	value: any,
}

return nil
