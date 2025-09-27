local roblox = require("@lune/roblox")

--stylua: ignore
--[[ EXPORT ]] export type BuilderContext = {
	download_place: (place_id: number, version: number?) -> roblox.DataModel,
	built_rbxl: roblox.DataModel,
}

--stylua: ignore
--[[ EXPORT ]] export type RbxlBuilder = (ctx: BuilderContext) -> roblox.DataModel

export type DarkluaRule =
	| {
		rule: "AppendTextComment",
		location: "start" | "end",
		text: string,
	}
	| {
		rule: "ComputeExpression",
	}
	| {
		rule: "ConvertLocalFunctionToAssign",
	}
	| {
		rule: "ConvertSquareRootCall",
	}
	| {
		rule: "FilterAfterEarlyReturn",
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
		rule: "RemoveEmptyDo",
	}
	| {
		rule: "RemoveNilDeclaration",
	}
	| {
		rule: "RemoveUnusedIfBranch",
	}
	| {
		rule: "RenameVariables",
		include_functions: boolean,
	}
	| {
		rule: "RemoveUnusedVariable",
	}
	| {
		rule: "RemoveUnusedWhile",
	}

--stylua: ignore
--[[ EXPORT ]] export type RbxlConfig = {
	builder: RbxlBuilder,

	project_file: string,

	sources: { [string]: string },

	network_declarations: { string },
	asset_directories: { string }?,
	
	constants: {
		[string]: Constant
	}?,
}

export type Constant =
	{
		kind: "env",

		name: string,
		type_str: string,
	}
	| {
		kind: "luau",

		type_str: string,
		value: any,
	}

return nil
