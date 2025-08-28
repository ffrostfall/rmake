local process = require("@lune/process")
local setup = require("@src/cli/setup")
local load_rmake_decl = require("@src/discovery/load_rmake_decl")
local generation = require("@src/generation")
local generation_context = require("@src/generation/generation_context")
local interface = require("@src/interface")
local styling = require("@src/styling")
local cli_parser = require("@src/util/cli_parser")
local help_color = styling.color.magenta_bright

local function hpfx_print(text: string)
	print(help_color(`{styling.modifier.bold("[help]")} {text}`))
end

local function help()
	hpfx_print("rmake usage:")
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

	parser:add("build_mode", "option", {
		aliases = {},
		required = false,
		help = "meow",
		default = "idk",
	})

	parser:parse(process.args)

	local subcommand = parser:get("subcommand")

	if subcommand == "dev" then
		local project = interface.run(load_rmake_decl())

		local place = parser:get("target")
		if not place then
			hpfx_print("must specify target place")
			return
		end

		local ctx = generation_context.new({
			build_mode = "debug",
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

		local project = interface.run(load_rmake_decl())

		local ctx = generation_context.new({
			build_mode = "debug",
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

		local project = interface.run(load_rmake_decl())

		local ctx = generation_context.new({
			build_mode = "debug",
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
		help()
	end
end

return cli
