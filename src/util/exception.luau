local process = require("@lune/process")
local styling = require("./styling")

local err_style = styling.combine_styles({ styling.color.red, styling.modifier.bold })

local function exception(message: string)
	local array = string.split(message, "\n")

	for _, line in array do
		print(err_style("[ERR]") .. "\t" .. line)
	end

	process.exit(1)
end

return exception
