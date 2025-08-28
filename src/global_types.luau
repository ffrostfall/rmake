local api = require("@definitions/api")
local net = require("@lune/net")
local process = require("@lune/process")

export type ProcessExecution = {
	kind: "ProcessExecution",

	program: string,
	args: { string },
	cwd: string?,
}

export type NetworkCall = {
	kind: "NetworkCall",

	params: net.FetchParams,
}

export type Action = ProcessExecution | NetworkCall

export type NetworkResult = net.FetchResponse
export type ProcessResult = process.ExecResult

export type CmdContext = {
	pkgs_sourcemap_file: string,
}

export type FileLocation = vector

export type PlaceRepresentation = {
	config: api.Place,

	name: string,
}

export type Project = {
	id_map: {
		[string]: number,
	},

	constant_decls: {
		[string]: api.Constant,
	},

	place_decls: { PlaceRepresentation },
}

return nil
