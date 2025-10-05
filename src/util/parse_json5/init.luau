local converter = require("@self/converter")
local lexer = require("@self/lexer")
local parser = require("@self/parser")
local prep = require("@self/prep")

local function parse_json5(source: string)
	local preppedSource = prep(source)
	local lexemes = lexer(preppedSource)
	local parsed = parser(lexemes)
	local converted = converter(parsed)

	return converted
end

return parse_json5
