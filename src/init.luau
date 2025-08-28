local process = require("@lune/process")
local cli = require("@src/cli")
local display_error = require("@src/display_error")

local success = xpcall(cli, display_error)

if not success then
	process.exit(1)
end
