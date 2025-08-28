local build = require("@ext/build")
local configure = require("@ext/configure")
local fs = require("@lune/fs")
local process = require("@lune/process")

local args = {}
for _, value in next, process.args do
	table.insert(args, value)
end

local with_zip = if table.find(args, "--zip") then true else false
local build_mode: ("release" | "debug")? = if table.find(args, "--debug")
	then "debug"
	elseif table.find(args, "--release") then "release"
	else nil

local only_native_platform = if table.find(args, "--my-platform") then true else false

if not build_mode then
	print("[err] unspecified build mode")
	return
end

print("configuring")
configure()

build.init()
build.executable(build_mode, with_zip, only_native_platform)

print("- " .. table.concat(fs.readDir("build"), "\n- "))
