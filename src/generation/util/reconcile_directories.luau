local fs = require("@lune/fs")

local function reconcile_directories(directories: { string })
	table.sort(directories, function(l, r): boolean
		return string.len(l) < string.len(r)
	end)

	for _, path in directories do
		if not fs.isDir(path) then
			fs.writeDir(path)
		end
	end
end

return reconcile_directories
