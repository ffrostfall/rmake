local process = require("@lune/process")
local setup = require("@src/cli/setup")
local build = require("@src/build")
local target_context = require("@src/build/target_context")
local runtime = require("@src/runtime")
local styling = require("@src/util/styling")
local cli_parser = require("@src/util/cli_parser")
local parse_json5 = require("@src/util/parse_json5")

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
		default = "target place",

		help = "target place",

		required = false,
	})

	parser:add("option", "option", {
		aliases = { "f" },
		default = "{}",
		help = "Passed options",
	})

	parser:parse(process.args)

	local subcommand = parser:get("subcommand")
	local passed_options = parse_json5(parser:get("option"))

	if subcommand == "help" then
		print(parser:help())
		return
	elseif subcommand == "setup" then
		setup()
		return
	end

	assert(type(passed_options) == "table")
	passed_options = passed_options :: { [string]: string }

	local result = runtime.run_rmake_file(passed_options)

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
	end

	return
end

return cli
