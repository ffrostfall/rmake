declare _G: {
	__ARCH: Architecture,
	__OS: OperatingSystem,
	
	__MODE: BuildMode
}

export type BuildMode = "debug" | "release"
export type Architecture = "x86_64" | "aarch64"
export type OperatingSystem = "linux" | "macos" | "windows"
