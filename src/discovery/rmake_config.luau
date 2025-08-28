local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local generation_types = require("@src/generation/generation_types")

local DOWNLOAD_SECRET_IDENTIFIER = "RMAKE_DOWNLOAD_KEY"
local UPLOAD_SECRET_IDENTIFIER = "RMAKE_UPLOAD_KEY"

local dev_ids: { [string]: number } = {}
local staging_ids: { [string]: number } = {}
local production_ids: { [string]: number } = {}

local upload_key: string?
local download_key: string?

local rmake_config = {}

function rmake_config.init()
	if not fs.isFile("./rmake.toml") then
		return
	end

	local rmake_ids = serde.decode("toml", fs.readFile("./rmake.toml"))

	if fs.isFile("./local_rmake.toml") then
		local local_rmake = serde.decode("toml", fs.readFile("./local_rmake.toml"))
	else
		download_key = process.env[DOWNLOAD_SECRET_IDENTIFIER]
		upload_key = process.env[UPLOAD_SECRET_IDENTIFIER]
	end
end

function rmake_config.secrets(): { upload: string?, download: string? }
	return {
		upload = upload_key,
		download = download_key,
	}
end

function rmake_config.set_id(context: generation_types.EnvironmentMode, name: string, id: number)
	if context == "local" then
		dev_ids[name] = id
	elseif context == "production" then
		production_ids[name] = id
	elseif context == "staging" then
		staging_ids[name] = id
	end
end

function rmake_config.get_id(context: generation_types.EnvironmentMode, name: string): number
	if context == "local" then
		return dev_ids[name]
	elseif context == "production" then
		return production_ids[name]
	elseif context == "staging" then
		return staging_ids[name]
	else
		return error("unimplemented")
	end
end

return rmake_config
