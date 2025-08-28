local api = require("@definitions/api")
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local task = require("@lune/task")
local generation_context = require("@self/generation_context")
local virtual_fs = require("@self/virtual_fs")
local rmake_config = require("@src/discovery/rmake_config")
local exec_network = require("@src/external/exec_network")
local exec_process = require("@src/external/exec_process")
local execute = require("@src/external/execute")
local util_download_place = require("@src/external/util_download_place")
local reconcile_directories = require("@src/generation/util/reconcile_directories")
local get_files_under_dir = require("@src/util/get_files_under_dir")
local log = require("@src/util/log")
local run_on_dir_changed = require("@src/util/run_on_dir_changed")

type ActionArray = { () -> () }

local function processing_project_file(ctx: generation_context.Identity, array: ActionArray)
	log.debug(`initial: processing_project_file`)

	table.insert(array, function()
		log.debug(`evaluating: processing_project_file`)

		local input_project_file = virtual_fs.read(ctx:project_file_path("input"))

		for source_name, source_path in ctx.place_representation.config.sources do
			input_project_file = string.gsub(input_project_file, `@{source_name}`, ctx:root_path() .. source_path)
		end

		input_project_file = string.gsub(input_project_file, "%./", ctx:root_path())

		input_project_file = string.gsub(input_project_file, "\\", "/")

		virtual_fs.write(ctx:project_file_path("processing"), input_project_file)
	end)
end

local function darklua_config(ctx: generation_context.Identity, array: ActionArray)
	log.debug(`initial: darklua_config`)

	table.insert(array, function()
		log.debug(`evaluating: darklua_config`)

		local config = {
			process = {} :: { any },
		}

		for name, value in ctx.project.constant_decls do
			local injected_identifier = `__{string.upper(name)}`

			if value.kind == "env" then
				table.insert(config.process, {
					rule = "inject_global_value",
					identifier = injected_identifier,

					env_json = name,
				})
			elseif value.kind == "luau" then
				local value_value_type = type(value.value)

				if
					value_value_type ~= "number"
					and value_value_type ~= "boolean"
					and value_value_type ~= "table"
					and value_value_type ~= "string"
				then
					error("meow")
				end

				table.insert(config.process, {
					rule = "inject_global_value",
					identifier = injected_identifier,

					value = value.value,
				})
			end
		end

		table.insert(config.process, {
			rule = "convert_require",
			current = {
				name = "luau",
			},
			target = {
				name = "roblox",
				indexing_style = "wait_for_child",
				rojo_sourcemap = ctx:sourcemap_path("processing"),
			},
		})

		if ctx.params.build_mode == "release" then
			table.insert(config.process, {
				rule = "rename_variables",
				include_functions = true,
				globals = { "$default", "$roblox" },
			})
		end

		table.insert(config.process, "convert_square_root_call")

		-- dead code elimination
		table.insert(config.process, "compute_expression")
		table.insert(config.process, "remove_unused_if_branch")
		table.insert(config.process, "remove_unused_variable")
		table.insert(config.process, "filter_after_early_return")
		table.insert(config.process, "remove_empty_do")

		virtual_fs.write(ctx:darklua_config_path(), serde.encode("json", config))
	end)
end

local function build_project_file(ctx: generation_context.Identity, array: ActionArray, exclude_directories: { string })
	log.debug(`initial: build_project_file`)

	table.insert(array, function()
		log.debug(`evaluating: build_project_file`)

		local input_project_file = virtual_fs.read(ctx:project_file_path("input"))

		for source_name, source_path in ctx.place_representation.config.sources do
			input_project_file = string.gsub(input_project_file, `@{source_name}`, ctx:place_fs_path() .. source_path)
		end

		input_project_file = string.gsub(input_project_file, "%./", ctx:root_path())

		input_project_file = string.gsub(input_project_file, "\\", "/")

		local project_file_dictionary = serde.decode("json", input_project_file)

		project_file_dictionary.globIgnorePaths = exclude_directories

		virtual_fs.write(ctx:project_file_path("build"), serde.encode("json", project_file_dictionary))
	end)
end

local function install_dependencies(ctx: generation_context.Identity, array: ActionArray)
	log.debug(`calling: install_dependencies`)

	table.insert(array, function()
		log.debug(`evaluating: install_dependencies`)

		execute(exec_process.wally_install())
		execute(exec_process.wally_patch_package())

		local project_file_json = {
			name = "packages",
			tree = {
				["$className"] = "DataModel",

				ReplicatedStorage = {
					["$className"] = "ReplicatedStorage",

					DevPackages = {
						["$path"] = { optional = ctx:root_path() .. "/DevPackages" },
					},
					Packages = {
						["$path"] = { optional = ctx:root_path() .. "/Packages" },
					},
				},
				ServerScriptService = {
					["$className"] = "ServerScriptService",

					ServerPackages = {
						["$path"] = { optional = ctx:root_path() .. "/ServerPackages" },
					},
				},
			},
		}

		virtual_fs.write(ctx:project_file_path("packages"), serde.encode("json", project_file_json))

		execute(exec_process.rojo_sourcemap(ctx:project_file_path("packages"), ctx:sourcemap_path("packages")))

		if fs.readDir("Packages") then
			execute((exec_process.wally_package_types(ctx:sourcemap_path("packages"), "Packages")))
		end
	end)
end

local function blink(ctx: generation_context.Identity, array: ActionArray)
	log.debug(`initial: blink`)

	install_dependencies(ctx, array)

	table.insert(array, function()
		log.debug(`evaluating: blink`)

		local contents = {}

		table.insert(contents, "option Casing = Snake")
		table.insert(contents, `option TypesOutput = "{ctx:place_fs_path() .. "net"}/net_types.luau"`)
		table.insert(contents, `option ServerOutput = "{ctx:place_fs_path() .. "net"}/net_server.luau"`)
		table.insert(contents, `option ClientOutput = "{ctx:place_fs_path() .. "net"}/net_client.luau"`)

		for _, import_path in ctx.place_representation.config.network_directories do
			log.trace(`getting .blink files under {ctx:root_path() .. import_path}`)
			local files = get_files_under_dir(ctx:root_path() .. import_path)

			for _, file in files do
				if string.sub(file, -6) == ".blink" then
					table.insert(contents, `import "{file}"`)
				end
			end
		end

		virtual_fs.write(ctx:blink_path(), table.concat(contents, "\n"))

		local command = exec_process.blink(ctx:blink_path())

		if ctx.params.subcommand == "dev-server" then
			table.insert(command.args, "--watch")

			task.spawn(function()
				execute(command)
			end)
		else
			execute(command)
		end
	end)
end

local function generate_declaration_file(ctx: generation_context.Identity, array: ActionArray)
	log.debug(`initial: generate_declaration_file`)

	local open = "declare _G: {\n"
	local close = "}\n"

	local type_decls: { string } = {}

	table.insert(array, function()
		log.debug(`evaluating: generate_declaration_file`)

		for constant, constant_value in ctx.project.constant_decls do
			local type_str = constant_value.type_str
			local name = `__{string.upper(constant)}`

			table.insert(type_decls, `\t{name}: {type_str},`)
		end

		local str = table.concat(type_decls, "\n")
		local file = open .. str .. close

		virtual_fs.write(ctx:globals_types_file(), file)
	end)
end

local function processing_sourcemap(ctx: generation_context.Identity, array: ActionArray)
	log.debug(`initial: processing_sourcemap`)

	processing_project_file(ctx, array)

	table.insert(array, function()
		log.debug(`evaluating: processing_sourcemap`)

		local command =
			exec_process.rojo_sourcemap(ctx:project_file_path("processing"), ctx:sourcemap_path("processing"))

		if ctx.params.subcommand == "dev-server" then
			table.insert(command.args, "--watch")

			local editor_sourcemap_command =
				exec_process.rojo_sourcemap(ctx:project_file_path("processing"), ctx:sourcemap_path("editor"))

			table.insert(editor_sourcemap_command.args, "--watch")

			task.spawn(function()
				execute(command)
			end)

			task.spawn(function()
				execute(editor_sourcemap_command)
			end)

			task.wait(0.1)
		else
			execute(command)
		end
	end)
end

local function darklua(ctx: generation_context.Identity, array: ActionArray)
	log.debug(`calling: darklua`)

	darklua_config(ctx, array, { "remove_empty_do" })
	generate_declaration_file(ctx, array)
	processing_sourcemap(ctx, array)

	table.insert(array, function()
		log.debug(`evaluating: darklua`)

		for _, source_path in ctx.place_representation.config.sources do
			local command = exec_process.darklua_process(
				ctx:root_path() .. source_path,
				ctx:place_fs_path() .. source_path,
				ctx:darklua_config_path()
			)

			if ctx.params.subcommand == "dev-server" then
				run_on_dir_changed(source_path, function()
					execute(command)
				end)
			else
				execute(command)
			end
		end
	end)
end

local function rojo_serve(ctx: generation_context.Identity, array: ActionArray)
	log.debug(`calling: rojo_serve`)

	blink(ctx, array)
	darklua(ctx, array)
	build_project_file(ctx, array, ctx.place_representation.config.asset_directories)

	table.insert(array, function()
		log.debug(`evaluating: rojo_serve`)

		local command = exec_process.rojo_serve(ctx:project_file_path("build"))

		task.spawn(function()
			execute(command)
		end)
	end)
end

local function rojo_build(ctx: generation_context.Identity, array: ActionArray)
	log.debug(`calling: rojo_build`)

	blink(ctx, array)
	darklua(ctx, array)
	build_project_file(ctx, array, ctx.place_representation.config.asset_directories)

	table.insert(array, function()
		log.debug(`evaluating: install_dependencies`)

		local command = exec_process.rojo_build(ctx:project_file_path("build"), ctx:rbxl_path("built"))

		execute(command)
	end)
end

local function build_place(ctx: generation_context.Identity, array: ActionArray)
	log.debug("calling: build_place")

	rojo_build(ctx, array)

	table.insert(array, function()
		log.debug("eval: build_place")

		local builder_ctx: api.BuilderContext = {
			download_place = function(place_id)
				local reply = util_download_place(place_id)

				assert(reply.ok)

				return roblox.deserializePlace(reply.body)
			end,

			built_rbxl = roblox.deserializePlace(virtual_fs.rawread(ctx:rbxl_path("built"))),
		}

		local dm = ctx.place_representation.config.builder(builder_ctx)

		virtual_fs.rawwrite(ctx:rbxl_path("output"), roblox.serializePlace(dm))
	end)
end

local function generation(ctx: generation_context.Identity)
	-- Prep
	rmake_config.init()

	reconcile_directories({
		ctx:build_fs_path(),
		ctx:place_fs_path(),
	})

	-- Populate
	ctx.project.constant_decls["BUILD_MODE"] =
		{ kind = "luau" :: "luau", type_str = '"debug" | "release"', value = ctx.params.build_mode } :: api.Constant

	local array: ActionArray = {}

	if ctx.params.subcommand == "push" then
		local universe_id = rmake_config.get_id(ctx.params.environment_mode, "universe")
		local place_id = rmake_config.get_id(ctx.params.environment_mode, ctx.place_representation.name)

		build_place(ctx, array)

		table.insert(array, function()
			local into = virtual_fs.rawread(ctx:rbxl_path("output"))

			exec_network.upload_place(universe_id, place_id, into)
		end)
	elseif ctx.params.subcommand == "local-build" then
		build_place(ctx, array)
	elseif ctx.params.subcommand == "dev-server" then
		rojo_serve(ctx, array)
	elseif ctx.params.subcommand == "install-dependencies" then
		install_dependencies(ctx, array)
	end

	-- De-duplication
	for i = #array, 1, -1 do
		local other = table.find(array, array[i], i + 1)

		if other then
			table.remove(array, i)
		end
	end

	-- Evaluate
	for i = 1, #array do
		array[i]()
	end
end

return generation
