local fs = require("@lune/fs")
local error_type = require("@src/error_type")

local function load_rmake_decl(): string
	local success, value = pcall(fs.readFile, "./rmake.luau")

	if success then
		return value
	else
		local not_found_err = string.find(string.lower(value), "not found")

		if not_found_err then
			local err: error_type.MissingRmakeDeclError = {
				from = "Discovery",
				kind = "MissingRmakeDeclError",
			}

			error(err)
		else
			local err: error_type.FileIoError = {
				from = "Discovery",
				kind = "FileIoError",
				err = value,
			}

			error(err)
		end
	end
end

return load_rmake_decl
