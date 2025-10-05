export type TokenKind =
	| "STRING"
	| "NULL"
	| "IGNORE"
	| "NUMBER"
	| "NEWLINE"
	| "EQUATES"
	| "COMMENT"
	| "INVALID"
	| "BOOLEAN"
	| "SEPARATOR"
	| "ARRAY_OPEN"
	| "IDENTIFIER"
	| "ARRAY_CLOSE"
	| "STRUCT_OPEN"
	| "STRUCT_CLOSE"

export type Token = {
	kind: TokenKind,
	value: string,
}

local function tokenize(character: string): Token
	local kind: TokenKind = if character == "\n"
		then "IGNORE"
		elseif character == ";" then "IGNORE"
		elseif character == "," then "IGNORE"
		elseif character == '"' then "STRING"
		elseif character == "'" then "STRING"
		elseif character == " " then "IGNORE"
		elseif character == ":" then "EQUATES"
		elseif character == "/" then "COMMENT"
		elseif character == "\t" then "IGNORE"
		elseif character == "[" then "ARRAY_OPEN"
		elseif character == "{" then "STRUCT_OPEN"
		elseif character == "]" then "ARRAY_CLOSE"
		elseif character == "}" then "STRUCT_CLOSE"
		else "INVALID"

	return {
		kind = kind,
		value = character,
	}
end

local function lexer(source: string): { Token }
	local characters = string.split(source, "")
	local tokens: { Token } = {}
	local cursor = 1

	while cursor <= #characters do
		local char: string = characters[cursor]
		cursor += 1

		if char == "\\" then
			cursor += 1
		end

		if char == "/" :: string then
			local next_char = characters[cursor]

			if next_char and next_char == "/" then
				while true do
					if characters[cursor] and characters[cursor] == "\n" then
						break
					end

					cursor += 1
				end
			else
				error("syntaxxxx")
			end

			continue
		end

		local alphanumerical = string.match(char, "%w") ~= nil
		if alphanumerical then
			local escaped = false
			local token: Token = {
				kind = "IDENTIFIER",
				value = char,
			}

			while not escaped do
				local current_character = characters[cursor]
				if not string.match(current_character, "[%w%.]") then
					escaped = true
					break
				elseif not current_character then
					error("what the carp")
				else
					token.value ..= current_character
				end

				cursor += 1
			end

			if string.match(token.value, "[%d%.]+") then
				token.kind = "NUMBER"
			end

			if token.value == "null" then
				token.kind = "NULL"
			elseif token.value == "true" or token.value == "false" then
				token.kind = "BOOLEAN"
			end

			table.insert(tokens, token)
			continue
		end

		local token = tokenize(char)
		if token.kind == "IGNORE" then
			continue
		end

		if token.kind == "STRING" then
			local escaped = false
			local escapeCharacter = char
			local value = ""

			while not escaped do
				local current_char = characters[cursor]
				if current_char == "\n" then
					error(cursor)
				elseif current_char == escapeCharacter then
					escaped = true
				elseif not current_char then
					error("what the carp")
				else
					value ..= current_char
				end

				cursor += 1
			end

			token.value = value
		end

		table.insert(tokens, token)
	end

	return tokens
end

return lexer
