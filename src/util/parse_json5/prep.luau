local function prep(source: string)
	local lineReturns = string.gsub(source, "\r", "")
	local multilineComments = string.gsub(lineReturns, "/%*.+%*/", "")

	return multilineComments
end

return prep
