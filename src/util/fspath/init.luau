local system = require("@lune/process")
local types = require("@self/types")

export type Nav = types.Nav
export type ValidPath = types.ValidPath

return (if system.os:lower():match("windows") then require("@self/windows") else require("@self/unix")) :: types.Api
