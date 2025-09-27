local fs = require("@lune/fs")
local process = require("@lune/process")
local setup = require("@src/cli/setup")
local generation = require("@src/generation")
local target_context = require("@src/generation/target_context")
local interface = require("@src/interface")
local styling = require("@src/util/styling")
local cli_parser = require("@src/util/cli_parser")
local log = require("@src/util/log")
local help_color = styling.color.magenta_bright

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
		required = false,
		help = "meow",
		default = "idk",
	})

	parser:add("release", "flag", {
		aliases = { "rel" },
		required = false,
	})

	parser:add("debug", "flag", {
		aliases = { "deb" },
		required = false,
	})

	parser:add("verbose", "flag", {
		aliases = { "v" },
		required = false,
	})

	parser:parse(process.args)

	if parser:has("verbose") then
		log.info("verbose mode enabled")
		log.level = 0
	end

	local subcommand = parser:get("subcommand")

	if subcommand == "dev" then
		local project = interface.run(fs.readFile("./rmake.luau"))

		local place = parser:get("target")
		if not place then
			hpfx_print("must specify target place")
			return
		end

		local ctx = target_context.new({
			build_mode = if parser:has("release") then "release" else "debug",
			environment_mode = "local",
			target_place = place,

			subcommand = "dev-server",
		}, project)

		generation(ctx)
	elseif subcommand == "push" then
		local place = parser:get("target")
		if not place then
			hpfx_print("must specify target place")
			return
		end

		local project = interface.run(fs.readFile("./rmake.luau"))

		local ctx = target_context.new({
			build_mode = if parser:has("debug") then "debug" else "release",
			environment_mode = "local",
			target_place = place,

			subcommand = "push",
		}, project)

		generation(ctx)
	elseif subcommand == "build" then
		local place = parser:get("target")
		if not place then
			hpfx_print("must specify target place")
			return
		end

		local project = interface.run(fs.readFile("./rmake.luau"))

		local ctx = target_context.new({
			build_mode = if parser:has("release") then "release" else "debug",
			environment_mode = "local",
			target_place = place,

			subcommand = "local-build",
		}, project)

		generation(ctx)
	elseif subcommand == "check" then
		error("unimplemented")
	elseif subcommand == "setup" then
		setup()
	else
		print(parser:help())
	end
end

return cli
