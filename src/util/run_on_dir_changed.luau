local fs = require("@lune/fs")
local task = require("@lune/task")
local log = require("./log")
local get_files_under_dir = require("./get_files_under_dir")

local function run_on_dir_changed(path: string, callback: () -> ()): thread
	local last_modified = {}

	for _, path in get_files_under_dir(path) do
		last_modified[path] = 0
	end

	log.trace(`set up watcher for path {path}`)
	return task.spawn(function()
		while true do
			for path, modified in last_modified do
				local newModified = fs.metadata(path).modifiedAt
				if newModified ~= modified then
					last_modified[path] = newModified
					log.trace(`path {path}`)
					task.spawn(callback)
					break
				end
			end

			task.wait(0.5)
		end
	end)
end

return run_on_dir_changed
