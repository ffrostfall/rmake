local process = require("@lune/process")
local fs = require("@lune/fs")

export type BuildContext = {
	for_arch: Architecture,
	for_os: string,

	mode: BuildMode,
}

local TARGET_OPERATING_SYSTEMS: { OperatingSystem } = { "linux", "macos", "windows" }
local TARGET_ARCHITECTURES: { Architecture } = { "aarch64", "x86_64" }
local PROJECT_NAME = "rmake"

local function env_vars(ctx: BuildContext)
	return {
		BUILD_ARCH = ctx.for_arch,
		BUILD_OS = ctx.for_os,
		BUILD_MODE = ctx.mode,
	}
end

local function execute(ctx: BuildContext, program: string, args: { string })
	print("[build] process spawned:", program)
	process.exec(program, args, {
		stdio = "forward",
		env = env_vars(ctx) :: { [string]: string },
		shell = if process.os == "windows" then "powershell" else nil,
	})
	print("[build] process completed")
end

local function build_with(ctx: BuildContext)
	local target_str = `{ctx.for_os}-{ctx.for_arch}`

	execute(ctx, "darklua", { "process", "src/", "build/source/" })

	execute(ctx, "lune", {
		"build",
		"build/source/init.luau",
		"--target",
		target_str,
		"--output",
		`build/bin/{PROJECT_NAME}_{target_str}`,
	})
end

local function zip(ctx: BuildContext, path: string, output: string)
	if process.os == "windows" then
		execute(ctx, "Compress-Archive", { "-Path", `"{path}"`, "-DestinationPath", `"build/{output}.zip"` })
	else
		execute(ctx, "tar", { "-czvf", `build/{output}.tar.gz`, path })
	end
end

local function build_executables(mode: BuildMode, with_zip: boolean, only_native_platform: boolean)
	print("[BUILD] beginning build")

	if only_native_platform then
		build_with({
			mode = mode,

			for_os = process.os,
			for_arch = process.arch,
		})
		return
	end

	for _, arch in TARGET_ARCHITECTURES do
		for _, os in TARGET_OPERATING_SYSTEMS do
			-- lol
			if os == "windows" and arch == "aarch64" then
				continue
			end

			local ctx: BuildContext = {
				mode = mode,
				for_os = os,
				for_arch = arch,
			}

			print(`[BUILD] building target \{mode {mode}, os {os}, arch {arch}\}`)
			build_with(ctx)

			local target_str = `{ctx.for_os}-{ctx.for_arch}`
			local path = `build/bin/{PROJECT_NAME}_{target_str}`

			if with_zip then
				zip(ctx, path .. if os == "windows" then ".exe" else "", `{PROJECT_NAME}_{target_str}`)
			end
		end
	end
end

local function init()
	print("[BUILD INIT] no build directory found, creating...")
	if not fs.isDir("build") then
		print("[BUILD INIT] reconciling build")
		fs.writeDir("build")
	end

	if fs.isDir("build/source") then
		fs.removeDir("build/source")
	end

	if fs.isDir("build/bin") then
		fs.removeDir("build/bin")
	end

	if not fs.isDir("build/bin") then
		fs.writeDir("build/bin")
	end
end

return {
	init = init,
	executable = build_executables,
}
