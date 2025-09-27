local fs = require("@lune/fs")
local luau = require("@lune/luau")
local task = require("@lune/task")
local declare_target = require("@src/runtime/public/declare_target")
local rbxl = require("@src/runtime/public/rbxl")
local runtime = {}

function runtime.init()
	local file_contents = fs.readFile("./rmake.luau")
	local bytecode = luau.compile(file_contents)

	local target_stuff = declare_target()

	local rmake_env = {
		declare_target = target_stuff.f,
		declare_rbxl = rbxl.new,
	}

	local runner = luau.load(bytecode, {
		environment = {
			require = function(path: string)
				if string.sub(path, 1, 5) == "@lune" then
					return (require :: any)(path)
				elseif path == "@rmake" then
					return rmake_env
				end

				return error("unsupported require at the moment")
			end,
		},
	})

	print("meow")
	local success, err = pcall(runner)
	print(success, err)
	print(target_stuff.targets)
end

task.spawn(function()
	print("bruh")
	runtime.init()
end)

return runtime
