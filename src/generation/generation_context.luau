local process = require("@lune/process")
local error_type = require("@src/error_type")
local reconcile_directories = require("@src/generation/util/reconcile_directories")
local global_types = require("@src/global_types")
local virtual_fs = require("./virtual_fs")
local generation_types = require("./generation_types")

export type SourcemapType = "packages" | "processing" | "editor"
export type ProjectFileType = "input" | "packages" | "build" | "processing"
export type RbxlType = "built" | "base" | "output"

local function absolute_from_cwd_relative(path: string)
	if string.sub(path, 1, 1) == "/" then
		path = string.sub(path, 2)
	end

	local cwd = process.cwd
	if _G.__MODE == "debug" then
		cwd ..= "debug/"
	end

	return cwd .. path
end

local generation_context = {}
local metatable = { __index = generation_context }
export type Identity = setmetatable<{
	project: global_types.Project,
	place_representation: global_types.PlaceRepresentation,

	params: {
		build_mode: generation_types.BuildMode,
		environment_mode: generation_types.EnvironmentMode,

		target_place: string,
		subcommand: generation_types.ActiveSubcommand,
	},
}, typeof(metatable)>

local function constructor(params: generation_types.GenerationParams, project: global_types.Project): Identity
	local self = setmetatable({}, metatable)

	self.project = project
	self.params = params

	local place_names, selected_place: global_types.PlaceRepresentation? = {}, nil
	for _, place in project.place_decls do
		local is_selected = place.name == params.target_place
		if is_selected then
			selected_place = place
			break
		end

		table.insert(place_names, place.name)
	end

	if not selected_place then
		local err: error_type.NoPlaceWithAliasFoundError = {
			from = "Rmake",
			kind = "NoPlaceWithAliasFoundError",

			input_alias = params.target_place,
			aliases = place_names,
		}
		error(err)
	end

	self.place_representation = selected_place

	local to_reconcile = {
		self:build_fs_path(),
		self:build_fs_path() .. "places",
		self:place_fs_path(),
	}
	for _, source_path in self.place_representation.config.sources do
		table.insert(to_reconcile, self:place_fs_path() .. source_path)
	end
	reconcile_directories(to_reconcile)

	virtual_fs.init()

	return self
end

function generation_context.project_file_path(self: Identity, kind: ProjectFileType): string
	if kind == "packages" then
		return self:build_fs_path() .. "packages.project.json"
	elseif kind == "processing" then
		return self:place_fs_path() .. "processing.project.json"
	elseif kind == "build" then
		return self:place_fs_path() .. "build.project.json"
	elseif kind == "input" then
		return self:root_path() .. self.place_representation.config.project_file_path
	end

	return error("unreachable")
end

function generation_context.sourcemap_path(self: Identity, kind: SourcemapType)
	if kind == "packages" then
		return self:build_fs_path() .. "pkg-sourcemap.json"
	elseif kind == "processing" then
		return self:place_fs_path() .. "processing-sourcemap.json"
	elseif kind == "editor" then
		return self:build_fs_path() .. "sourcemap.json"
	end

	return error("unreachable")
end

function generation_context.blink_path(self: Identity)
	return self:place_fs_path() .. "main.blink"
end

function generation_context.darklua_config_path(self: Identity)
	return self:place_fs_path() .. "darklua.json"
end

function generation_context.rbxl_path(self: Identity, kind: RbxlType)
	if kind == "output" then
		return self:build_fs_path() .. `{self.place_representation.name}.rbxl`
	elseif kind == "built" then
		return self:place_fs_path() .. "build.rbxl"
	elseif kind == "base" then
		return self:place_fs_path() .. "base.rbxl"
	end

	return error("unreachable")
end

function generation_context.globals_types_file(self: Identity)
	return absolute_from_cwd_relative(`build/globals.d.luau`)
end

function generation_context.build_fs_path(self: Identity): string
	return absolute_from_cwd_relative(`build/`)
end

function generation_context.place_fs_path(self: Identity): string
	return absolute_from_cwd_relative(`build/places/{self.place_representation.name}/`)
end

function generation_context.root_path(self: Identity): string
	return process.cwd .. if _G.__MODE == "debug" then "debug/" else ""
end

function generation_context.close(self: Identity)
	virtual_fs.done()
end

return { new = constructor }
