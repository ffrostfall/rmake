local fs = require("@lune/fs")
local serde = require("@lune/serde")
local build_path = require("@src/util/build_path")
local log = require("@src/util/log")

-- path: hash
local fs_hashes: { [string]: string } = {}

local virtual_fs = {}

function virtual_fs.init()
	if not fs.isDir("build") then
		fs.writeDir("build")
	end

	local hashes_exists = fs.isFile(build_path .. "rmake_hashes.toml")
	if not hashes_exists then
		fs.writeFile(build_path .. "rmake_hashes.toml", "")
		log.trace("hash file does not exist, creating one...")
	else
		log.debug("reading hashes")
		fs_hashes = serde.decode("toml", fs.readFile(build_path .. "rmake_hashes.toml"))
	end
end

function virtual_fs.rawread(path: string): string
	log.debug(`fs rawread: {path}`)
	return fs.readFile(path)
end

function virtual_fs.rawwrite(path: string, contents: string)
	log.debug(`fs rawwrite: {path}`)
	return fs.writeFile(path, contents)
end

function virtual_fs.write(path: string, contents: string)
	local content_hash = serde.hash("md5", contents)

	if fs_hashes[path] == content_hash then
		log.debug(`fs write dodge, path: {path}`)
		return
	else
		log.debug("fs write hit")
		fs_hashes[path] = content_hash

		fs.writeFile(path, contents)
	end
end

function virtual_fs.read(path: string)
	log.debug(`fs read: {path}`)
	return fs.readFile(path)
end

function virtual_fs.done()
	log.debug("writing hashes")
	fs.writeFile(build_path .. "rmake_hashes.toml", serde.encode("toml", fs_hashes))
end

return virtual_fs
