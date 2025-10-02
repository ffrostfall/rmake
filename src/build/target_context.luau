local process = require("@lune/process")
local virtual_fs = require("./virtual_fs")

export type SourcemapType = "packages" | "processing" | "editor"
export type ProjectFileType = "input" | "packages" | "build" | "processing"
export type RbxlType = "built" | "base" | "output"
export type Command = "dev" | "install-dependencies" | "build"

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

local target_context = {}
local metatable = { __index = target_context }
export type Identity = setmetatable<{
	identifier: string,
	command: Command,

	target_config: {
		sources: { [string]: string },
		project_file: string,
	},
}, typeof(metatable)>

local function constructor(command: Command, identifier: string): Identity
	local self = setmetatable({}, metatable)

	self.command = command
	self.identifier = identifier

	self.target_config = {
		sources = {},
	}

	return self
end

function target_context.project_file_path(self: Identity, kind: ProjectFileType): string
	if kind == "packages" then
		return self:build_fs_path() .. "packages.project.json"
	elseif kind == "processing" then
		return self:place_fs_path() .. "processing.project.json"
	elseif kind == "build" then
		return self:place_fs_path() .. "build.project.json"
	elseif kind == "input" then
		return self:root_path() .. self.target_config.project_file
	end

	return error("unreachable")
end

function target_context.sourcemap_path(self: Identity, kind: SourcemapType)
	if kind == "packages" then
		return self:build_fs_path() .. "pkg-sourcemap.json"
	elseif kind == "processing" then
		return self:place_fs_path() .. "processing-sourcemap.json"
	elseif kind == "editor" then
		return self:build_fs_path() .. "sourcemap.json"
	end

	return error("unreachable")
end

function target_context.blink_path(self: Identity)
	return self:place_fs_path() .. "main.blink"
end

function target_context.darklua_config_path(self: Identity)
	return self:place_fs_path() .. "darklua.json"
end

function target_context.rbxl_path(self: Identity, kind: RbxlType)
	if kind == "output" then
		return self:build_fs_path() .. `{self.identifier}.rbxl`
	elseif kind == "built" then
		return self:place_fs_path() .. "build.rbxl"
	elseif kind == "base" then
		return self:place_fs_path() .. "base.rbxl"
	end

	return error("unreachable")
end

function target_context.globals_types_file(self: Identity)
	return absolute_from_cwd_relative(`build/globals.d.luau`)
end

function target_context.build_fs_path(self: Identity): string
	return absolute_from_cwd_relative(`build/`)
end

function target_context.place_fs_path(self: Identity): string
	return absolute_from_cwd_relative(`build/places/{self.identifier}/`)
end

function target_context.root_path(self: Identity): string
	return process.cwd
end

function target_context.close(self: Identity)
	virtual_fs.done()
end

return { new = constructor }
