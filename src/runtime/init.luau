local api = require("@definitions/api")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local task = require("@lune/task")
local public_api = require("@self/public_api")

export type Project = {
	rbxl_decls: { [string]: api.RbxlConfig },
}

local runtime = {}

function runtime.run_rmake_file(passed_options: { [string]: string }): public_api.Identity
	local file_contents = fs.readFile("./rmake.luau")
	local bytecode = luau.compile(file_contents)

	local api = public_api.new(passed_options)

	local runner = luau.load(bytecode, {
		environment = {
			require = function(path: string)
				if string.sub(path, 1, 5) == "@lune" then
					return (require :: any)(path)
				elseif path == "@rmake" then
					return api:create_table()
				end

				return error("unsupported require at the moment")
			end,
		},
	})

	runner()

	return api
end

return runtime
