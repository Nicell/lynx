local net = require("@lune/net")
local Router = require("router")
local Context = require("context")
local static = require("static")

type Context = Context.Context
export type Handler = (c: Context) -> net.ServeResponse
export type Middleware = (c: Context, next: () -> ()) -> ()
export type MatchResponse = { { params: { [string]: string }, handler: Handler | Middleware, score: number } }

local Lynx = {}
Lynx.__index = Lynx

export type Lynx = typeof(Lynx)

local defaultNotFound: Handler = function(c: Context): net.ServeResponse
	c:status(404)
	return c:text("Not Found")
end

function Lynx.new()
	local self = setmetatable({}, Lynx)
	self.router = Router.new()
	self.routes = {}
	self.notFoundHandler = defaultNotFound
	return self
end

function Lynx:route(path: string, app: Lynx)
	for _, route in app.routes do
		self:addRoute(route.method, path .. route.path, route.handler)
	end
	return self
end

function Lynx:addRoute(method: string, path: string, handler: Handler | Middleware)
	self.router:add(method, path, handler)
	table.insert(self.routes, { method = method, path = path, handler = handler })
	return self
end

function Lynx:use(path: string | Middleware, handler: Middleware?)
	local realPath = path
	if handler == nil then
		if type(path) == "string" then
			error("Handler must be provided when using a path")
		end
		handler = path
		realPath = "*"
	end

	self.router:add("ALL", realPath, handler)
	return self
end

function Lynx:on(method: string, path: string, handler: Handler)
	return self:addRoute(method, path, handler)
end

function Lynx:all(path: string, handler: Handler)
	return self:on("ALL", path, handler)
end

function Lynx:get(path: string, handler: Handler)
	return self:on("GET", path, handler)
end

function Lynx:post(path: string, handler: Handler)
	return self:on("POST", path, handler)
end

function Lynx:put(path: string, handler: Handler)
	return self:on("PUT", path, handler)
end

function Lynx:delete(path: string, handler: Handler)
	return self:on("DELETE", path, handler)
end

function Lynx:patch(path: string, handler: Handler)
	return self:on("PATCH", path, handler)
end

function Lynx:static(path: string, directory: string)
	return self:get(path:gsub("/$", "") .. "/*", static(path, directory))
end

function Lynx:notFound(handler: Handler)
	self.notFoundHandler = handler
	return self
end

function Lynx:dispatch(req: net.ServeRequest): net.ServeResponse
	local match: MatchResponse = self.router:match(req.method, req.path)

	local context = Context.new(req, self.notFoundHandler)

	if not match then
		return self.notFoundHandler(context)
	end

	if #match == 1 then
		local handler = match[1].handler
		context.req.params = match[1].params
		local success, result = pcall(handler, context)
		if not success then
			return self.notFoundHandler(context)
		end
		return result
	end

	local function dispatch(i)
		if i > #match then
			return self.notFoundHandler(context)
		end

		context.req.params = match[i].params

		local handler = match[i].handler

		return handler(context, function()
			dispatch(i + 1)
		end)
	end

	dispatch(1)

	if context.finalized then
		return context.res
	else
		return self.notFoundHandler(context)
	end
end

function Lynx:serve(port: number?)
	self.server = net.serve(port or 3000, function(req)
		return self:dispatch(req)
	end)
	return self
end

return Lynx
