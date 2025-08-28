local fs = require("@lune/fs")

local function get_files_under_dir(directory: string): { string }
	local paths: { string } = {}

	local contents = fs.readDir(directory)
	if not contents then
		return {}
	end

	for _, filePath in contents do
		local target = directory .. "/" .. filePath

		if fs.isDir(target) then
			local subdirectoryContents = get_files_under_dir(target)

			for _, element in subdirectoryContents do
				table.insert(paths, target)
			end
		else
			table.insert(paths, target)
		end
	end

	return paths
end

return get_files_under_dir
