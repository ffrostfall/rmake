local roblox = require("@lune/roblox")

--stylua: ignore
--[[ EXPORT ]] export type BuilderContext = {
	download_place: (place_id: number, version: number?) -> roblox.DataModel,
	built_rbxl: roblox.DataModel,
}

--stylua: ignore
--[[ EXPORT ]] export type RbxlBuilder = (ctx: BuilderContext) -> roblox.DataModel

--stylua: ignore
--[[ EXPORT ]] export type Constant = { type: string, value: unknown, }

export type DarkluaRule =
	| {
		rule: "AppendTextComment",
		location: "start" | "end",
		text: string,
	}
	| {
		rule: "ConvertLocalFunctionToAssign",
	}
	| {
		rule: "ConvertSquareRootCall",
	}
	| {
		rule: "GroupLocalAssignment",
	}
	| {
		rule: "RemoveAssertions",
		preserve_arguments_side_effects: boolean,
	}
	| {
		rule: "RemoveDebugProfiling",
	}
	| {
		rule: "RemoveNilDeclaration",
	}
	| {
		rule: "RenameVariables",
		include_functions: boolean,
		globals: { string },
	}

--stylua: ignore
--[[ EXPORT ]] export type RbxlConfig = {
	builder: RbxlBuilder,

	project_file: string,

	sources: { [string]: string },

	network_directories: { string },
	asset_directories: { string }?,
	
	constants: {
		-- Identifier: Type
		[string]: {
			value: unknown,
			type: string,
		}
	}?,
	
	darklua_rules: { DarkluaRule }
}

return nil
