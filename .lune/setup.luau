local fs = require("@lune/fs")
local process = require("@lune/process")

if process.args[1] == "fresh" then
	if fs.isDir("debug") then
		fs.removeDir("debug")
	end
end

fs.writeDir("debug")

fs.writeDir("debug/user_dir/")
fs.writeDir("debug/build/")
