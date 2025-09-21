local error_type = require("./error_type")
local styling = require("@src/util/styling")
local process = require("@lune/process")

local err_style = styling.combine_styles({ styling.color.red_bright, styling.modifier.bold })
local err_prefix = err_style("[ERR] ")

local rt_err_style = styling.color.red
local rt_trace_style = styling.color.blue

type ErrMeta = {
	trace: string,
	line: number,
}

local function pfx_print(text: string)
	print(`{err_prefix}{text}`)
end

local function render_internal_error(err: string, level: number)
	if type(err) == "userdata" then
		print(err)
		return
	end

	local trace = debug.traceback("[REMOVE]", level)

	trace = string.gsub(trace, "STANDALONE", "<bundled>")
	err = string.gsub(err, "STANDALONE", "<bundled>")

	trace = string.gsub(trace, process.cwd, "")
	trace = string.gsub(trace, "\\", "/")

	local lines = {
		"internal rmake error:",
		"",
		`\t{rt_err_style(err)}`,
	}

	for i, value in string.split(trace, "\n") do
		if i == 1 then
			continue
		end

		value = string.gsub(value, "src/generation:", "src/generation/init.luau:")

		table.insert(lines, `\t{rt_trace_style(value)}`)
	end

	table.insert(lines, "contact ffrostfall ig")

	for _, line in lines do
		pfx_print(line)
	end
end

local function display_interface_err(err: error_type.InterfaceError)
	if err.kind == "CompilationError" then
		pfx_print("compilation error in rmake.luau")
		pfx_print("\t" .. tostring(err.luau_err))
	elseif err.kind == "LoadError" then
		pfx_print("compilation error in rmake.luau")
		pfx_print("\t" .. tostring(err.load_err))
	elseif err.kind == "RuntimeError" then
		pfx_print(`runtime error in rmake.luau`)

		local split = string.split(err.runtime_err, "\n")
		local err_msg = table.remove(split, 1)
		assert(err_msg)

		pfx_print(rt_err_style(err_msg))
		for _, line in split do
			pfx_print(`\t{rt_trace_style(line)}`)
		end

		process.exit(err.code)
	elseif err.kind == "InputError" then
		pfx_print("interface usage error:")
	else
		pfx_print(`uncaught interface error`)
		pfx_print(`kind: {err.kind}`)
	end
end

local function display_generation_err(err: error_type.GenerationError, meta: ErrMeta)
	if err.kind == "BuildGraphNilNodeRefError" then
		render_internal_error(`nil node reference, ref value: {err.ref_value}`, 4)
	elseif err.kind == "BuildGraphNodeMismatchError" then
		render_internal_error("BuildGraphNodeMismatchError", 4)
	elseif err.kind == "BuildGraphMissingDependencyError" then
		render_internal_error(`action is missing dependency {err.dependency_expected}`, 4)
	else
		pfx_print(`uncaught generation error`)
		pfx_print(`kind: {err.kind}`)
	end
end

local function display_rmake_err(err: error_type.RmakeError, meta: ErrMeta)
	if err.kind == "NoPlaceWithAliasFoundError" then
		pfx_print(`Invalid place selected: {err.input_alias}`)
		if #err.aliases == 0 then
			pfx_print("You have NO places. Your game serves ZERO players. You should delete this repo NOW!")
		else
			pfx_print(`Available places to choose from: {table.concat(err.aliases, ", ")}`)
		end
	else
		pfx_print(`uncaught rmake error`)
		pfx_print(`kind: {err.kind}`)
	end
end

local function display_error(err: error_type.Error | string)
	if type(err) == "string" or type(err) == "userdata" then
		render_internal_error(tostring(err), 3)
		return
	end

	err = err :: error_type.Error

	local line = debug.info(2, "l")
	local trace = debug.traceback("[error display]", 3)

	local err_meta: ErrMeta = {
		line = line,
		trace = trace,
	}

	if err.from == "Interface" then
		display_interface_err(err, err_meta)
	elseif err.from == "Generation" then
		display_generation_err(err, err_meta)
	elseif err.from == "Rmake" then
		display_rmake_err(err, err_meta)
	else
		pfx_print(`uncaught internal error`)
		pfx_print(`from: {err.from}`)
		pfx_print(`kind: {err.kind}`)
	end
end

return display_error
