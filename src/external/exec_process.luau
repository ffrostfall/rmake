local fs = require("@lune/fs")
local process = require("@lune/process")
local global_types = require("@src/global_types")
local log = require("@src/util/log")

local exec_process = {}

function exec_process.rojo_sourcemap(
	project_file: string,
	output_file: string,
	cwd: string?
): global_types.ProcessExecution
	if _G.__MODE == "debug" then
		process.exec(
			"rojo",
			{ "sourcemap", project_file, "--output", output_file, "--absolute" },
			{ stdio = "forward" }
		)
	end

	return {
		kind = "ProcessExecution",

		program = "rojo",
		args = { "sourcemap", project_file, "--output", output_file, "--absolute" },
		cwd = cwd,
	}
end

function exec_process.wally_install(): global_types.ProcessExecution
	return {
		kind = "ProcessExecution",

		program = "wally",
		args = { "install" },
	}
end

function exec_process.wally_patch_package(): global_types.ProcessExecution
	return {
		kind = "ProcessExecution",

		program = "wally-patch-package",
		args = {},
	}
end

function exec_process.wally_package_types(
	sourcemap_path: string,
	which_packages: "Packages" | "ServerPackages" | "DevPackages"
): global_types.ProcessExecution
	return {
		kind = "ProcessExecution",

		program = "wally-package-types",
		args = { "--sourcemap", sourcemap_path, which_packages .. "/" },
	}
end

function exec_process.darklua_process(input: string, output: string, config_path: string): global_types.ProcessExecution
	if _G.__MODE == "debug" then
		process.exec("darklua", { "process", input, output, "--config", config_path }, {
			stdio = "forward",
			cwd = "debug/",
		})
	end

	-- DARKLUA FIX: Darklua breaks when the input is an absolute path

	-- DARKLUA FIX (Part 2)
	-- This fix exposes ANOTHER bug in darklua which breaks convert_require.
	-- I would rather implement my own file watcher than deal with that.

	-- local cwd = process.cwd

	-- if fspath.has_root(input) then
	-- 	log.trace("applying darklua patch")
	-- 	local input_nav = fspath.to_nav(input)
	-- 	local cwd_nav = fspath.to_nav(cwd)

	-- 	for i = #cwd_nav, 1, -1 do
	-- 		if input_nav[i] == cwd_nav[i] then
	-- 			table.remove(input_nav, i)
	-- 		end
	-- 	end

	-- 	input = fspath.to_str(input_nav)
	-- end

	return {
		kind = "ProcessExecution",

		program = "darklua",

		args = { "process", input, output, "--config", config_path },
	}
end

function exec_process.rojo_serve(project_file_path: string): global_types.ProcessExecution
	return {
		kind = "ProcessExecution",

		program = "rojo",

		args = { "serve", project_file_path },
	}
end

function exec_process.blink(path: string): global_types.ProcessExecution
	return {
		kind = "ProcessExecution",

		program = "blink",

		args = { path, "--yes" },
	}
end

function exec_process.rojo_build(project_file_path: string, output_path: string): global_types.ProcessExecution
	if _G.__MODE == "debug" then
		fs.copy("tests/test_data/baseplate.rbxl", output_path, true)
		log.trace("mocking rojo build")
	end

	return {
		kind = "ProcessExecution",

		program = "rojo",

		args = { "build", project_file_path, "--output", output_path },
	}
end

return exec_process
