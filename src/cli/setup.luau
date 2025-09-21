local fs = require("@lune/fs")
local serde = require("@lune/serde")
local included_definitions = require("@src/included_definitions")
local styling = require("@src/util/styling")
local user_path = require("@src/util/user_path")

local setup_color = styling.color.blue_bright

local function spfx_print(text: string)
	print(setup_color(`{styling.modifier.bold("[setup]")} {text}`))
end

local function setup()
	fs.writeDir(`{user_path}/.rmake/`)
	fs.writeFile(`{user_path}/.rmake/rmake.luau`, included_definitions)
	fs.writeFile(
		`{user_path}/.rmake/.luaurc`,
		serde.encode("json", {
			languageMode = "strict",

			aliases = {
				lune = "~/.lune/.typedefs/0.10.1/",
			},
		})
	)

	spfx_print("successfully set up type definitions in the user directory")
	spfx_print("add the following to your .luaurc for intellisense:")
	spfx_print(`\t\t"rmake": "~/.rmake/"`)
end

return setup
