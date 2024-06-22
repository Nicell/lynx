local net = require("@lune/net")
local Context = {}
Context.__index = Context

export type LynxRequest = net.ServeRequest & { params: { [string]: string } }
export type Context = typeof(setmetatable({} :: { req: LynxRequest, res: net.ServeResponse }, Context))

function Context.new(req: net.ServeRequest, notFoundHandler)
	local self = setmetatable({}, Context)
	self.req = req
	self.res = {
		headers = {},
	}
	self.state = {}
	self.notFoundHandler = notFoundHandler
	self.finalized = false
	return self
end

function Context:finalize()
	self.finalized = true
	return self.res
end

function Context:set(key: string, value: any)
	self.state[key] = value
end

function Context:get(key: string): any
	return self.state[key]
end

function Context:header(key: string, value: string)
	self.res.headers[key] = value
end

function Context:status(status: number)
	self.res.status = status
end

function Context:body(body: buffer | string, status: number?, headers: any?): net.ServeResponse
	self.res.body = body
	self.res.status = status or self.res.status or 200

	if headers then
		for k, v in headers do
			self.res.headers[k] = v
		end
	end

	return self:finalize()
end

function Context:text(text: string, status: number?, headers: any?): net.ServeResponse
	self:header("Content-Type", "text/plain; charset=utf-8")
	return self:body(text, status, headers)
end

function Context:json(json: any, status: number?, headers: any?): net.ServeResponse
	self:header("Content-Type", "application/json")
	local body = net.jsonEncode(json)

	return self:body(body, status, headers)
end

function Context:html(html: string, status: number?, headers: any?): net.ServeResponse
	self:header("Content-Type", "text/html; charset=utf-8")
	return self:body(html, status, headers)
end

function Context:notFound(): net.ServeResponse
	return self.notFoundHandler(self)
end

function Context:redirect(location, status: number?)
	self:header("Location", location)
	self:status(status or 302)
	return self:finalize()
end

return Context
