local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")
local log = require("@src/util/log")

local function create_logged_action<T>(f: T): T
	return function(...)
		return f(...)
	end
end

local function execute_command(program: string, args: { string }, cwd: string?): process.ExecResult
	log.trace(`{program} {table.concat(args, " ")}`)
	log.trace("stdout:")

	return process.exec(program, args, {
		stdio = "forward",
		cwd = cwd,
	})
end

local rojo_sourcemap = create_logged_action(
	function(project_file: string, output_file: string, watch: boolean?, cwd: string?)
		return execute_command("rojo", {
			"sourcemap",
			project_file,
			"--output",
			output_file,
			"--absolute",
			if watch then "--watch" else nil :: any,
		}, cwd)
	end
)

local rojo_build = create_logged_action(function(project_file: string, output_file: string, cwd: string?)
	return execute_command("rojo", { "build", project_file, "--output", output_file }, cwd)
end)

local rojo_serve = create_logged_action(function(project_file: string, cwd: string?)
	return task.spawn(function()
		execute_command("rojo", { "serve", project_file }, cwd)
	end)
end)

local wally_install = create_logged_action(function(cwd: string?)
	return execute_command("wally", { "install" }, cwd)
end)

local wally_pkg_types = create_logged_action(function(sourcemap_path: string, package_folder: string, cwd: string?)
	return execute_command("wally-package-types", { "--sourcemap", sourcemap_path, package_folder .. "/" }, cwd)
end)

local wally_patch_package = create_logged_action(function()
	return execute_command("wally-patch-package", {})
end)

local blink = create_logged_action(function(path: string, watch: boolean?, cwd: string?)
	return execute_command("blink", { path, "--yes", if watch then "--watch" else nil :: any }, cwd)
end)

local darklua = create_logged_action(function(input: string, output: string, config_path: string)
	return execute_command("darklua", { "process", input, output, "--config", config_path })
end)

local download_place_file = create_logged_action(function(place_id: string, auth: string)
	local response = net.request({
		url = `https://apis.roblox.com/asset-delivery-api/v1/assetId/{auth}`,
		headers = {
			["x-api-key"] = auth,
		},
	})

	local response_table = serde.decode("json", response.body)
	assert(response_table and response_table.location, "request denied")

	local response_location = response_table.location

	return net.request(response_location :: any)
end)

local upload_place_file = create_logged_action(
	function(universe_id: string, place_id: string, rbxl: string, auth: string)
		return net.request({
			url = `https://apis.roblox.com/universes/v1/{universe_id}/places/{place_id}/versions?versionType=Published`,

			headers = {
				["Content-Type"] = "application/octet-stream",
				["x-api-key"] = auth,
			},

			body = rbxl,
		})
	end
)

return {
	rojo_sourcemap = rojo_sourcemap,
	rojo_build = rojo_build,
	rojo_serve = rojo_serve,

	wally_install = wally_install,
	wally_pkg_types = wally_pkg_types,
	wally_patch_package = wally_patch_package,

	blink = blink,
	darklua = darklua,

	download_place_file = download_place_file,
	upload_place_file = upload_place_file,
}
