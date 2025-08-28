local process = require("@lune/process")

local function base_path()
	if _G.__MODE == "release" then
		if _G.__OS == "windows" then
			return `{process.env["USERPROFILE"]}/`
		end

		return "~/"
	elseif _G.__MODE == "debug" then
		return "./debug/user_dir/"
	end

	return "./debug/user_dir"
end

return base_path()
