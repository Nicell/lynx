export type Runtime = "lute" | "lune"

export type Headers = { [string]: string? }

export type ServeRequest = {
	method: string,
	path: string,
	body: string,
	query: { [string]: string },
	headers: { [string]: string },
}

export type ServeResponse = {
	status: number?,
	body: (buffer | string)?,
	headers: Headers?,
}

export type ServeHandle = any

export type ServeConfig = {
	port: number?,
	address: string?,
}

type RuntimeImpl = {
	runtime: Runtime,
	env: { [string]: string? },
	jsonEncode: (value: any) -> string,
	jsonDecode: (value: string) -> any,
	readFile: (path: string) -> buffer | string,
	serve: (config: ServeConfig, handler: (ServeRequest) -> ServeResponse) -> ServeHandle,
	compress: ((format: string, body: buffer | string) -> buffer | string)?,
}

local function tryRequire(moduleName: string): (boolean, any)
	return pcall(require, moduleName)
end

local function hostnameFromAddress(address: string?): string
	local hostname = address or "0.0.0.0"
	hostname = hostname:gsub("^%a+://", "")
	hostname = hostname:gsub("/.*$", "")
	hostname = hostname:gsub(":%d+$", "")
	return if hostname == "" then "0.0.0.0" else hostname
end

local function luteResponse(response: ServeResponse): any
	if response.body and typeof(response.body) == "buffer" then
		return {
			status = response.status,
			body = buffer.tostring(response.body),
			headers = response.headers,
		}
	end

	return response :: any
end

local function loadLute(): RuntimeImpl?
	local serverOk, server = tryRequire("@lute/net/server")
	if not serverOk then
		return nil
	end

	local json = require("@std/json")
	local fs = require("@std/fs")
	local process = require("@std/process")

	return {
		runtime = "lute",
		env = process.env :: { [string]: string? },
		jsonEncode = function(value: json.Value): string
			return json.serialize(value)
		end,
		jsonDecode = function(value: string): json.Value
			return json.deserialize(value)
		end,
		readFile = function(path: string): string
			return fs.readFileToString(path)
		end,
		serve = function(config: ServeConfig, handler: (ServeRequest) -> ServeResponse): ServeHandle
			return server.serve({
				hostname = hostnameFromAddress(config.address),
				port = config.port or 3000,
				handler = function(req)
					return luteResponse(handler(req))
				end,
			})
		end,
		compress = nil,
	}
end

local function loadLune(): RuntimeImpl
	local net = require("@lune/net")
	local serde = require("@lune/serde")
	local fs = require("@lune/fs")
	local process = require("@lune/process")

	return {
		runtime = "lune",
		env = process.env,
		jsonEncode = function(value: any): string
			return serde.encode("json", value)
		end,
		jsonDecode = function(value: string): any
			return serde.decode("json", value)
		end,
		readFile = function(path: string): string
			return fs.readFile(path)
		end,
		serve = function(config: ServeConfig, handler: (ServeRequest) -> ServeResponse): ServeHandle
			return net.serve(config.port or 3000, {
				address = config.address or "http://0.0.0.0",
				handleRequest = handler :: (net.ServeRequest) -> net.ServeResponse,
			})
		end,
		compress = function(format: string, body: buffer | string): string
			return serde.compress(format :: serde.CompressDecompressFormat, body)
		end,
	}
end

return loadLute() or loadLune()
