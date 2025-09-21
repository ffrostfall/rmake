local styling = require("@src/util/styling")

local debug_prefix_style = styling.combine_styles({ styling.color.grey, styling.modifier.bold })
local debug_style = styling.color.grey
local trace_prefix_style = styling.combine_styles({ styling.color.blue, styling.modifier.bold })
local trace_style = styling.color.white_bright
local info_prefix_style = styling.combine_styles({ styling.color.magenta_bright, styling.modifier.bold })
local info_style = styling.combine_styles({ styling.color.white_bright })

local log = {}

function log.debug(text: string)
	print(debug_prefix_style("[DEBUG] ") .. debug_style(text))
end

function log.trace(text: string)
	print(trace_prefix_style("[TRACE] ") .. trace_style(text))
end

function log.info(text: string)
	print(info_prefix_style("[INFO] " .. info_style(text)))
end

return log
