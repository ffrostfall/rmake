local net = require("@lune/net")
local process = require("@lune/process")
local global_types = require("@src/global_types")
local log = require("@src/util/log")

local function execute(action: global_types.Action): any
	if _G.__MODE == "debug" then
		log.trace(`mocking: {action.kind}`)
	end

	if action.kind == "ProcessExecution" then
		if _G.__MODE == "debug" then
			log.trace(`command: "{action.program} {table.concat(action.args, " ")}", with cwd: [{action.cwd}]`)
			return
		end

		log.info(`process execution: {action.program} {table.concat(action.args, " ")}`)
		local res = process.exec(action.program, action.args, {
			stdio = "forward",
			cwd = action.cwd,
		})

		log.trace(`process ok: {res.code}, process exit code: {res.code}`)
		if res.code ~= 0 then
			log.trace("dumping stderr")
			return
		end
		return
	elseif action.kind == "NetworkCall" then
		if _G.__MODE == "debug" then
			log.trace(`network call to url [{action.params.url}]`)
			return
		end

		log.info(`{action.params.method} request to URL {action.params.url}`)

		return net.request(action.params)
	else
		log.trace(`unexpected log kind {action.kind}`)
	end

	return error("unreachable")
end

local function execute_with_errors_handled(...: any): ...any
	return execute(...)
end

type ExecuteTy =
	& ((op: global_types.NetworkCall) -> global_types.NetworkResult)
	& ((op: global_types.ProcessExecution) -> global_types.ProcessResult)

return execute_with_errors_handled :: ExecuteTy
