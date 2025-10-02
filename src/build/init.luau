local api = require("@definitions/api")
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local task = require("@lune/task")
local target_context = require("@self/target_context")
local virtual_fs = require("@self/virtual_fs")
local get_files_under_dir = require("@src/util/get_files_under_dir")
local log = require("@src/util/log")
local run_on_dir_changed = require("@src/util/run_on_dir_changed")
local external_actions = require("@src/external_actions")

type ActionArray = { () -> () }

local function reconcile_directories(directories: { string })
	table.sort(directories, function(l, r): boolean
		return string.len(l) < string.len(r)
	end)

	for _, path in directories do
		if not fs.isDir(path) then
			fs.writeDir(path)
		end
	end
end

local function processing_project_file(ctx: target_context.Identity, array: ActionArray)
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

local function darklua_config(ctx: target_context.Identity, array: ActionArray)
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

local function build_project_file(ctx: target_context.Identity, array: ActionArray, exclude_directories: { string })
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

local function install_dependencies(ctx: target_context.Identity, array: ActionArray)
	log.debug(`calling: install_dependencies`)

	table.insert(array, function()
		log.debug(`evaluating: install_dependencies`)

		external_actions.wally_install()
		external_actions.wally_patch_package()

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

		external_actions.rojo_sourcemap(ctx:project_file_path("packages"), ctx:sourcemap_path("packages"))

		if fs.readDir("Packages") then
			external_actions.wally_pkg_types(ctx:sourcemap_path("packages"), "Packages")
		end

		if fs.isDir("ServerPackages") then
			external_actions.wally_pkg_types(ctx:sourcemap_path("packages"), "ServerPackages")
		end

		if fs.isDir("DevPackages") then
			external_actions.wally_pkg_types(ctx:sourcemap_path("packages"), "DevPackages")
		end
	end)
end

local function blink(ctx: target_context.Identity, array: ActionArray)
	log.debug(`initial: blink`)

	table.insert(array, function()
		log.debug(`evaluating: blink`)

		local contents = {}

		table.insert(contents, "option Casing = Snake")
		table.insert(contents, `option TypesOutput = "{ctx:place_fs_path() .. "net"}/types.luau"`)
		table.insert(contents, `option ServerOutput = "{ctx:place_fs_path() .. "net"}/server.luau"`)
		table.insert(contents, `option ClientOutput = "{ctx:place_fs_path() .. "net"}/client.luau"`)

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

		if ctx.subcommand == "dev-server" then
			external_actions.blink(ctx:blink_path(), false)

			task.spawn(function()
				external_actions.blink(ctx:blink_path(), true)
			end)
		else
			external_actions.blink(ctx:blink_path(), false)
		end
	end)
end

local function generate_declaration_file(ctx: target_context.Identity, array: ActionArray)
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

local function processing_sourcemap(ctx: target_context.Identity, array: ActionArray)
	log.debug(`initial: processing_sourcemap`)

	processing_project_file(ctx, array)

	table.insert(array, function()
		log.debug(`evaluating: processing_sourcemap`)

		if ctx.subcommand == "dev-server" then
			task.spawn(function()
				external_actions.rojo_sourcemap(ctx:project_file_path("processing"), ctx:sourcemap_path("editor"))
			end)

			task.spawn(function()
				external_actions.rojo_sourcemap(ctx:project_file_path("processing"), ctx:sourcemap_path("processing"))
			end)

			task.wait(0.15)
		else
			external_actions.rojo_sourcemap(ctx:project_file_path("processing"), ctx:sourcemap_path("processing"))
		end
	end)
end

local function darklua(ctx: target_context.Identity, array: ActionArray)
	log.debug(`calling: darklua`)

	darklua_config(ctx, array, { "remove_empty_do" })
	generate_declaration_file(ctx, array)
	processing_sourcemap(ctx, array)

	table.insert(array, function()
		log.debug(`evaluating: darklua`)

		for _, source_path in ctx.place_representation.config.sources do
			if ctx.subcommand == "dev-server" then
				run_on_dir_changed(source_path, function()
					external_actions.darklua(
						ctx:root_path() .. source_path,
						ctx:place_fs_path() .. source_path,
						ctx:darklua_config_path()
					)
				end)
			else
				external_actions.darklua(
					ctx:root_path() .. source_path,
					ctx:place_fs_path() .. source_path,
					ctx:darklua_config_path()
				)
			end
		end
	end)
end

local function rojo_serve(ctx: target_context.Identity, array: ActionArray)
	log.debug(`calling: rojo_serve`)

	blink(ctx, array)
	darklua(ctx, array)
	build_project_file(ctx, array, ctx.place_representation.config.asset_directories)

	table.insert(array, function()
		log.debug(`evaluating: rojo_serve`)

		external_actions.rojo_serve(ctx:project_file_path("build"))
	end)
end

local function rojo_build(ctx: target_context.Identity, array: ActionArray)
	log.debug(`calling: rojo_build`)

	blink(ctx, array)
	darklua(ctx, array)
	build_project_file(ctx, array, ctx.place_representation.config.asset_directories)

	table.insert(array, function()
		log.debug(`evaluating: rojo_build`)

		external_actions.rojo_build(ctx:project_file_path("build"), ctx:rbxl_path("built"))
	end)
end

local function build_place(ctx: target_context.Identity, array: ActionArray)
	log.debug("calling: build_place")

	install_dependencies(ctx, array)
	rojo_build(ctx, array)

	table.insert(array, function()
		log.debug("eval: build_place")

		local builder_ctx: api.BuilderContext = {
			download_place = function(place_id: number)
				local reply = external_actions.download_place_file(tostring(place_id), "")

				assert(reply.ok)

				return roblox.deserializePlace(reply.body)
			end,

			built_rbxl = roblox.deserializePlace(virtual_fs.rawread(ctx:rbxl_path("built"))),
		}

		local dm = ctx.place_representation.config.builder(builder_ctx)

		virtual_fs.rawwrite(ctx:rbxl_path("output"), roblox.serializePlace(dm))
	end)
end

local function generation(ctx: target_context.Identity)
	-- Prep
	local to_reconcile = {
		ctx:build_fs_path(),
		ctx:place_fs_path(),

		ctx:build_fs_path() .. "places",
	}

	for _, source_path in ctx.target_config.sources do
		table.insert(to_reconcile, ctx:place_fs_path() .. source_path)
	end

	reconcile_directories(to_reconcile)

	virtual_fs.init()

	local array: ActionArray = {}

	if ctx.command == "build" then
		build_place(ctx, array)
	elseif ctx.command == "dev-server" then
		rojo_serve(ctx, array)
	elseif ctx.command == "install-dependencies" then
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
