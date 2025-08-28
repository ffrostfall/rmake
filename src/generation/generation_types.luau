export type BuildMode = "release" | "debug"
export type ActiveSubcommand = "dev-server" | "push" | "local-build" | "install-dependencies"
export type EnvironmentMode = "production" | "staging" | "local"

export type GenerationParams = {
	build_mode: BuildMode,
	environment_mode: EnvironmentMode,

	target_place: string,
	subcommand: ActiveSubcommand,
}

return nil
