local parser = require("@self/parser")

type Value = string | boolean | nil | number | { Value } | { [string]: Value }

local function converter(valueToken: parser.AstValueToken): Value
	if valueToken.kind == "ARRAY" then
		local result = {}

		for _, token in valueToken.value do
			table.insert(result, converter(token))
		end

		return result
	elseif valueToken.kind == "STRUCT" then
		local result: { [string]: Value } = {}

		for _, value in valueToken.value do
			result[value.key] = converter(value.value)
		end

		return result
	end

	return valueToken.value
end

return converter
