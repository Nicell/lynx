local net = require("@lune/net")
local Context = {}
Context.__index = Context

export type LynxRequest = net.ServeRequest & { params: { [string]: string } }
export type Context = typeof(setmetatable(
	{} :: {
		req: LynxRequest,
		res: net.ServeResponse,
		state: { [string]: any },
		notFoundHandler: (c: Context) -> net.ServeResponse,
		finalized: boolean,
	},
	Context
))

function Context.new(req: net.ServeRequest, notFoundHandler): Context
	local self = setmetatable({}, Context)
	self.req = req :: LynxRequest
	self.res = {
		headers = {},
	}
	self.state = {}
	self.notFoundHandler = notFoundHandler
	self.finalized = false
	return self
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

function Context.header(self: Context, key: string, value: string)
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
	local body = net.jsonEncode(json)

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
