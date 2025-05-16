local net = require("@lune/net")
local serde = require("@lune/serde")

local Context = {}
Context.__index = Context

export type LynxRequest = net.ServeRequest & {
	params: { [string]: string },
	valid: { [string]: any },
	json: (self: LynxRequest) -> any,
}

type ContextData = {
	req: LynxRequest,
	res: net.ServeResponse,
	state: { [string]: any },
	notFoundHandler: (c: Context) -> net.ServeResponse,
	finalized: boolean,
}

export type Context = typeof(setmetatable({} :: ContextData, Context))

function Context.new(req: LynxRequest, notFoundHandler): Context
	local self = {}
	self.req = req
	self.res = {
		headers = {},
	} :: net.ServeResponse
	self.state = {}
	self.notFoundHandler = notFoundHandler
	self.finalized = false
	return setmetatable(self, Context)
end

function Context.finalize(self: Context)
	self.finalized = true
	return self.res
end

function Context.set(self: Context, key: string, value: any)
	self.state[key] = value
	return self
end

function Context.get(self: Context, key: string): any
	return self.state[key]
end

function Context.header(self: Context, key: string, value: string?)
	assert(self.res.headers, "Response headers not initialized")
	self.res.headers[key] = value
	return self
end

function Context.status(self: Context, status: number)
	self.res.status = status
	return self
end

function Context.body(self: Context, body: buffer | string, status: number?, headers: any?): net.ServeResponse
	self.res.body = body
	self.res.status = status or self.res.status or 200

	if headers then
		assert(self.res.headers, "Response headers not initialized")
		for k, v in headers do
			self.res.headers[k] = v
		end
	end

	return self:finalize()
end

function Context.text(self: Context, text: string, status: number?, headers: any?): net.ServeResponse
	self:header("Content-Type", "text/plain; charset=utf-8")
	return self:body(text, status, headers)
end

function Context.json(self: Context, json: any, status: number?, headers: any?): net.ServeResponse
	self:header("Content-Type", "application/json")
	local body = serde.encode("json", json)

	return self:body(body, status, headers)
end

function Context.html(self: Context, html: string, status: number?, headers: any?): net.ServeResponse
	self:header("Content-Type", "text/html; charset=utf-8")
	return self:body(html, status, headers)
end

function Context.notFound(self: Context): net.ServeResponse
	return self.notFoundHandler(self)
end

function Context.redirect(self: Context, location, status: number?)
	self:header("Location", location)
	self:status(status or 302)
	return self:finalize()
end

return Context
