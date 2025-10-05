local lexer = require("@self/lexer")

export type AstValueToken =
	{
		kind: "NUMBER",
		value: number,
	}
	| {
		kind: "STRING",
		value: string,
	}
	| {
		kind: "NULL",
		value: nil,
	}
	| {
		kind: "BOOLEAN",
		value: boolean,
	}
	| {
		kind: "STRUCT",
		value: AstStructToken,
	}
	| {
		kind: "ARRAY",
		value: AstArrayToken,
	}

type AstArrayToken = { AstValueToken }
type AstStructToken = { KeyValuePair }
type KeyValuePair = {
	key: string,
	value: AstValueToken,
}

local function parser(lexemes: { lexer.Token }): (AstValueToken, number)
	local cursor = 1
	local currentToken = lexemes[cursor]

	if currentToken.kind == "STRING" then
		return {
			kind = "STRING",
			value = currentToken.value,
		}, cursor
	elseif currentToken.kind == "NUMBER" then
		return {
			kind = "NUMBER",
			value = tonumber(currentToken.value) or error("Invalid number"),
		}, cursor
	elseif currentToken.kind == "STRUCT_OPEN" then
		local struct: AstStructToken = {}
		cursor += 1

		while lexemes[cursor].kind ~= "STRUCT_CLOSE" do
			local key = lexemes[cursor].value
			cursor += 1

			if lexemes[cursor].kind ~= "EQUATES" then
				error("Expected equates")
			end
			cursor += 1

			local value, newCursor = parser({ table.unpack(lexemes, cursor) })
			cursor += newCursor

			table.insert(struct, {
				key = key,
				value = value,
			})

			if lexemes[cursor].kind == "SEPARATOR" then
				cursor += 1
			end
		end

		return {
			kind = "STRUCT",
			value = struct,
		}, cursor
	elseif currentToken.kind == "ARRAY_OPEN" then
		local array: AstArrayToken = {}
		cursor += 1

		while lexemes[cursor].kind ~= "ARRAY_CLOSE" do
			if lexemes[cursor].kind == "SEPARATOR" then
				cursor += 1
			end

			local value, newCursor = parser({ table.unpack(lexemes, cursor) })
			cursor += newCursor

			table.insert(array, value)
		end

		return {
			kind = "ARRAY",
			value = array,
		}, cursor
	elseif currentToken.kind == "NULL" then
		return {
			kind = "NULL",
			value = nil,
		}, cursor
	elseif currentToken.kind == "BOOLEAN" then
		return {
			kind = "BOOLEAN",
			value = if currentToken.value == "true" then true else false,
		}, cursor
	else
		error("Invalid token")
	end
end

return parser
