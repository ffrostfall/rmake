-- Usage errors
export type NoPlaceWithAliasFoundError = {
	from: "Rmake",
	kind: "NoPlaceWithAliasFoundError",

	input_alias: string,
	aliases: { string },
}

export type RmakeError = NoPlaceWithAliasFoundError

-- Interface errors
export type CompilationErr = {
	from: "Interface",
	kind: "CompilationError",

	luau_err: string,
}

export type LoadError = {
	from: "Interface",
	kind: "LoadError",

	load_err: string,
}

export type RuntimeError = {
	kind: "RuntimeError",
	from: "Interface",

	runtime_err: string,

	code: number,
}

export type RmakeApiError = {
	from: "Interface",
	kind: "ApiError",

	text: string,
}

export type InterfaceError = | LoadError | CompilationErr | RuntimeError | RmakeApiError

-- Generation errors
export type CompileCommandError = {
	from: "Generation",
	kind: "CompileCommandError",
	command: string,
}

export type BuildGraphNilNodeRefError = {
	from: "Generation",
	kind: "BuildGraphNilNodeRefError",

	ref_value: unknown,
}

export type BuildGraphNodeMismatchError = {
	from: "Generation",
	kind: "BuildGraphNodeMismatchError",
}

export type BuildGraphMissingDependencyError = {
	from: "Generation",
	kind: "BuildGraphMissingDependencyError",

	dependency_expected: string,
}

export type BuildGraphUnimplementedEvaluator = {
	from: "Generation",
	kind: "BuildGraphUnimplementedEvaluator",
}

export type GenerationError =
	| BuildGraphUnimplementedEvaluator
	| BuildGraphMissingDependencyError
	| BuildGraphNodeMismatchError
	| BuildGraphNilNodeRefError
	| CompileCommandError

-- Discovery errors
export type MissingRmakeSecretError = {
	from: "Discovery",
	kind: "MissingSecretError",

	secret_name: string,
}

export type MissingRmakeDeclError = {
	from: "Discovery",
	kind: "MissingRmakeDeclError",
}

export type FileIoError = {
	from: "Discovery",
	kind: "FileIoError",
	err: string,
}

export type ProjectFileMissingError = {
	from: "Discovery",
	kind: "ProjectFileMissingError",
	project_file: string,
}

export type DiscoveryError = | MissingRmakeSecretError | FileIoError | ProjectFileMissingError | MissingRmakeDeclError

export type Error = | RmakeError | DiscoveryError | InterfaceError | GenerationError

return nil
