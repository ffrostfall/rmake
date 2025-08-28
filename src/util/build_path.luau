local function build_path()
	if _G.__MODE == "release" then
		return "build/"
	elseif _G.__MODE == "debug" then
		return "debug/build/"
	end

	return "debug/build/"
end

return build_path()
