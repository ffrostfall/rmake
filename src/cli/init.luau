local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local build = require("@src/build")
local target_context = require("@src/build/target_context")
local included_definitions = require("@src/included_definitions")
local runtime = require("@src/runtime")
local styling = require("@src/util/styling")
local cli_parser = require("@src/util/cli_parser")
local log = require("@src/util/log")

local help_color = styling.color.magenta_bright
local setup_color = styling.color.blue_bright

local function spfx_print(text: string)
	print(setup_color(`{styling.modifier.bold("[setup]")} {text}`))
end

local function hpfx_print(text: string)
	print(help_color(`{styling.modifier.bold("[help]")} {text}`))
end

local function cli()
	local parser = cli_parser.parser()

	parser:add("subcommand", "positional", {
		aliases = {},
		default = "help",

		help = "subcommand",

		required = false,
	})

	parser:add("target", "positional", {
		aliases = {},
		default = "target place",

		help = "target place",

		required = false,
	})

	parser:add("options", "option", {
		aliases = {},
		default = "{}",
		help = "Passed options",
	})

	parser:add("verbose", "option", {
		aliases = { "v" },
	})

	parser:parse(process.args)

	if parser:get("verbose") then
		log.level = tonumber(parser:get("verbose")) or 4
	end

	local subcommand = parser:get("subcommand")
	local passed_options_str = parser:get("options")
	local options = {}

	if passed_options_str then
		for _, value in string.split(passed_options_str, ",") do
			local pack = string.split(value, "=")

			options[pack[1]] = pack[2]
		end
	end

	if subcommand == "help" or not subcommand then
		hpfx_print("Usage: rmake <subcommand> <options>")
		hpfx_print("")
		hpfx_print("Subcommands:")
		hpfx_print("\t- push <target>")
		hpfx_print("\t\tOptions: --options <JSON5 struct>")
		hpfx_print("\t- setup")
		hpfx_print("\t- build <target>")
		hpfx_print("\t\tOptions: --options <JSON5 struct>")
		hpfx_print("\t- dev <target>")
		hpfx_print("\t\tOptions: --options <JSON5 struct>")
		hpfx_print("\t- install-dependencies")
		return
	elseif subcommand == "setup" then
		local user_path = if _G.__OS == "windows" then process.env["HOME"] else "~/"

		fs.writeDir(`{user_path}/.rmake/`)
		fs.writeFile(`{user_path}/.rmake/rmake.luau`, included_definitions)
		fs.writeFile(
			`{user_path}/.rmake/.luaurc`,
			serde.encode("json", {
				languageMode = "strict",

				aliases = {
					lune = "~/.lune/.typedefs/0.10.1/",
				},
			})
		)

		spfx_print("successfully set up type definitions in the user directory")
		spfx_print("add the following to your .luaurc for intellisense:")
		spfx_print(`\t\t"rmake": "~/.rmake/"`)
		return
	end

	local result = runtime.run_rmake_file(options)

	if subcommand == "dev" then
		local place = parser:get("target")
		if not place then
			hpfx_print("must specify target place")
			return
		end

		local ctx = target_context.new("dev", place, result:index_config(place))

		build(ctx)
	elseif subcommand == "push" then
		local place = parser:get("target")
		if not place then
			hpfx_print("must specify target place")
			return
		end

		local ctx = target_context.new("push", place, result:index_config(place))

		build(ctx)
	elseif subcommand == "build" then
		local place = parser:get("target")
		if not place then
			hpfx_print("must specify target place")
			return
		end

		local ctx = target_context.new("build", place, result:index_config(place))

		build(ctx)
	elseif subcommand == "install-dependencies" then
		local place = parser:get("target")
		if not place then
			hpfx_print("must specify target place")
			return
		end

		local ctx = target_context.new("install-dependencies", place, result:index_config(place))

		build(ctx)
	end

	return
end

return cli
