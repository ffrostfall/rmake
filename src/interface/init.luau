local luau = require("@lune/luau")
local lib = require("@src/interface/lib")
local global_types = require("@src/global_types")
local log = require("@src/util/log")

local ERR_EXIT = [[rmake declaration file returned something other than a number/nil]]

local function compile(file: string)
	return luau.compile(file, {
		debugLevel = 2,
		optimizationLevel = 1,
	})
end

local interface = {}

function interface.run(file: string): global_types.Project
	local decl_bytecode: string
	do
		local success, value: string = pcall(compile, file)

		if not success then
			local err: error_type.CompilationErr = {
				from = "Interface",
				kind = "CompilationError",

				luau_err = value,
			}

			error(err)
		end

		decl_bytecode = value :: any
	end

	local new_lib = lib()

	local load_fn: () -> unknown
	do
		local success, value: string | () -> unknown = pcall(
			luau.load,
			decl_bytecode,
			{
				debugName = "decl_file",
				environment = {
					require = function(str)
						if str == "@rmake" then
							return new_lib
						end

						return error("rmake does not support requires at this time")
					end,
				},
				injectGlobals = true,
				codegenEnabled = false,
			} :: luau.LoadOptions
		)

		if not success then
			assert(type(value) == "string", "TYPE_MISMATCH")

			local err: error_type.LoadError = {
				from = "Interface",
				kind = "LoadError",
				load_err = value,
			}

			error(err)
		end

		assert(type(value) == "function", "TYPE_MISMATCH")

		log.debug("setting load fn")
		load_fn = value
		log.debug(tostring(load_fn))
	end

	do
		local success, value: unknown = xpcall(load_fn, function(err)
			local trace = debug.traceback(err, 2)

			local split = string.split(trace, "\n")

			for i = #split, 1, -1 do
				local line = split[i]
				if string.find(line, "mlua") then
					table.remove(split, i)
				end
			end

			local ret = table.concat(split, "\n")

			ret = string.gsub(ret, `%[string "decl_file"%]`, "./rmake.luau")
			ret = string.gsub(ret, "STANDALONE", "rmake")

			return ret
		end)

		if not success then
			assert(type(value) == "string", "TYPE_MISMATCH")

			local err: error_type.RuntimeError = {
				from = "Interface",
				kind = "RuntimeError",

				runtime_err = value,
				code = 1,
			}

			error(err)
		end

		if value ~= nil and type(value) ~= "number" then
			local err: error_type.RuntimeError = {
				from = "Interface",
				kind = "RuntimeError",

				runtime_err = ERR_EXIT,
				code = 1,
			}

			error(err)
		end

		if type(value) == "number" and value ~= 0 then
			local err: error_type.RuntimeError = {
				from = "Interface",
				kind = "RuntimeError",

				runtime_err = "exit code is not 1",
				code = value,
			}

			error(err)
		end
	end

	return (new_lib :: any)._internal
end

return interface
