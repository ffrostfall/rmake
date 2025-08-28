local fs = require("@lune/fs")

local function configure()
	print("[CONFIGURE] reading api definitions file")
	local api_string = fs.readFile("definitions/api.luau")

	api_string = string.gsub(api_string, "\nexport type", "\ntype")
	api_string = string.gsub(api_string, "return nil", "")

	print("[CONFIGURE] reading definitions api file")
	local def_string = fs.readFile("definitions/init.luau")

	print("[CONFIGURE] linking (lol)")
	def_string = string.gsub(def_string, "--%[%[LINK%]%] (.-)\n", api_string)
	def_string = string.gsub(def_string, "api.", "")

	print("[CONFIGURE] writing definition file")
	fs.writeFile("src/included_definitions.luau", `return [====[{def_string}]====]`)
end

return configure
