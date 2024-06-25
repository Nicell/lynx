local net = require("@lune/net")
local Router = require("router")
local Context = require("context")
local static = require("static")

type Context = Context.Context
export type Handler = (c: Context) -> net.ServeResponse
export type ErrorHandler = (c: Context, error: string) -> net.ServeResponse
export type Middleware = (c: Context, next: () -> ()) -> ()
export type MatchResponse = { { params: { [string]: string }, handler: Handler | Middleware, score: number } }

local Lynx = {}
Lynx.__index = Lynx

export type Lynx = typeof(Lynx)
export type LynxConfig = {
	port: number?,
	address: string?,
}

local defaultNotFound: Handler = function(c: Context): net.ServeResponse
	c:status(404)
	return c:text("Not Found")
end

local defaultErrorHandler: ErrorHandler = function(c: Context, error: string): net.ServeResponse
	print("Error:", error)
	c:status(500)
	return c:text("Internal Server Error")
end

function Lynx.new()
	local self = setmetatable({}, Lynx)
	self.router = Router.new()
	self.routes = {}
	self.notFoundHandler = defaultNotFound
	self.errorHandler = defaultErrorHandler
	return self
end

function Lynx:route(path: string, app: Lynx)
	for _, route in app.routes do
		self:addRoute(route.method, path .. route.path, route.handler)
	end
	return self
end

function Lynx:addRoute(method: string, path: string, handler: Handler | Middleware)
	method = method:upper()
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

function Lynx:onError(handler: Handler)
	self.errorHandler = handler
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
		local success, result = pcall(handler, context, function()
			return self.notFoundHandler(context) -- If the single handler is a middleware, it must be not found
		end)
		
		if success then
			return result or context.res
		else
			return self.errorHandler(context, result)
		end
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

	local success, result = pcall(dispatch, 1)

	if not success then
		return self.errorHandler(context, result)
	elseif context.finalized then
		return context.res
	else
		return self.notFoundHandler(context)
	end
end

function Lynx:serve(config: LynxConfig?)
	local c = config or {}
	self.server = net.serve(c.port or 3000, {
		address = c.address or "http://0.0.0.0",
		handleRequest = function(req)
			return self:dispatch(req)
		end,
	})
	return self
end

return Lynx
