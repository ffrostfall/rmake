local cli = require("@src/cli")
local styling = require("@src/util/styling")
local process = require("@lune/process")

local err_style = styling.combine_styles({ styling.color.red_bright, styling.modifier.bold })

local function pfx_print(text: string)
	print(`{err_style("[ERR] ")}{text}`)
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
		`\t{styling.color.red(err)}`,
	}

	for i, value in string.split(trace, "\n") do
		if i == 1 then
			continue
		end

		value = string.gsub(value, "src/generation:", "src/generation/init.luau:")

		table.insert(lines, `\t{styling.color.blue(value)}`)
	end

	table.insert(lines, "contact ffrostfall ig")

	for _, line in lines do
		pfx_print(line)
	end
end

local success = xpcall(cli, function(err)
	if type(err) == "string" or type(err) == "userdata" then
		render_internal_error(tostring(err), 3)
		return
	end

	err = err :: error_type.Error

	pfx_print(`uncaught internal error`)
	pfx_print(`from: {err.from}`)
	pfx_print(`kind: {err.kind}`)
end)

if not success then
	process.exit(1)
end
