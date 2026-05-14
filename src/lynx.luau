local Runtime = require("./runtime")
local Router = require("./router")
local Context = require("./context")
local static = require("./static")
local Types = require("./types")

type Router = Router.Router
export type Context = Context.Context
export type LynxRequest = Context.LynxRequest
export type Handler = Types.Handler
export type ErrorHandler = Types.ErrorHandler
export type Middleware = Types.Middleware
export type MatchResponse = Types.MatchResponse

type MixedHandler = Handler | Middleware

local Lynx = {}
Lynx.__index = Lynx

type LynxData = {
	router: Router,
	routes: { { method: string, path: string, handler: Handler | Middleware } },
	notFoundHandler: Handler,
	errorHandler: ErrorHandler,
	server: Runtime.ServeHandle?,
}

export type Lynx = setmetatable<LynxData, typeof(Lynx)>

export type LynxConfig = {
	port: number?,
	address: string?,
}

local defaultNotFound: Handler = function(c: Context): Runtime.ServeResponse
	c:status(404)
	return c:text("Not Found")
end

local defaultErrorHandler: ErrorHandler = function(c: Context, error: string): Runtime.ServeResponse
	print("Error:", error)
	c:status(500)
	return c:text("Internal Server Error")
end

local function mergePath(base: string, sub: string): string
	local prefix = if base:sub(1, 1) == "/" then base else "/" .. base
	if sub == "/" then
		return prefix
	end

	local separator = if prefix:sub(-1) == "/" then "" else "/"
	local child = if sub:sub(1, 1) == "/" then sub:sub(2) else sub
	return `{prefix}{separator}{child}`
end

function Lynx.new(): Lynx
	local self = {}
	self.router = Router.new()
	self.routes = {}
	self.notFoundHandler = defaultNotFound
	self.errorHandler = defaultErrorHandler
	self.server = nil :: Runtime.ServeHandle?
	return setmetatable(self, Lynx)
end

function Lynx.route(self: Lynx, path: string, app: Lynx)
	for _, route in app.routes do
		self:addRoute(route.method, mergePath(path, route.path), route.handler)
	end
	return self
end

function Lynx.addRoute(self: Lynx, method: string, path: string, handler: Handler | Middleware)
	method = method:upper()
	self.router:add(method, path, handler)
	table.insert(self.routes, { method = method, path = path, handler = handler })
	return self
end

function Lynx.use(self: Lynx, path: string | Middleware, handler: Middleware?, ...: Middleware)
	local realPath = path
	if handler == nil then
		if type(path) == "string" then
			error("Handler must be provided when using a path")
		end
		handler = path
		realPath = "*"
	end

	assert(typeof(realPath) == "string", "Path must be a string")
	assert(typeof(handler) == "function", "Handler must be a function")
	self:addRoute("ALL", realPath, handler)
	for _, h in { ... } do
		self:addRoute("ALL", realPath, h)
	end
	return self
end

function Lynx.on(self: Lynx, method: string, path: string, handler: MixedHandler, ...: MixedHandler)
	self:addRoute(method, path, handler)
	for _, h in { ... } do
		self:addRoute(method, path, h)
	end
	return self
end

function Lynx.all(self: Lynx, path: string, handler: MixedHandler, ...: MixedHandler)
	return self:on("ALL", path, handler, ...)
end

function Lynx.get(self: Lynx, path: string, handler: MixedHandler, ...: MixedHandler)
	return self:on("GET", path, handler, ...)
end

function Lynx.post(self: Lynx, path: string, handler: MixedHandler, ...: MixedHandler)
	return self:on("POST", path, handler, ...)
end

function Lynx.put(self: Lynx, path: string, handler: MixedHandler, ...: MixedHandler)
	return self:on("PUT", path, handler, ...)
end

function Lynx.delete(self: Lynx, path: string, handler: MixedHandler, ...: MixedHandler)
	return self:on("DELETE", path, handler, ...)
end

function Lynx.patch(self: Lynx, path: string, handler: MixedHandler, ...: MixedHandler)
	return self:on("PATCH", path, handler, ...)
end

function Lynx.static(self: Lynx, path: string, directory: string)
	return self:get(path:gsub("/$", "") .. "/*", static(path, directory))
end

function Lynx.notFound(self: Lynx, handler: Handler)
	self.notFoundHandler = handler
	return self
end

function Lynx.onError(self: Lynx, handler: ErrorHandler)
	self.errorHandler = handler
	return self
end

function RequestJson(self: LynxRequest)
	return Runtime.jsonDecode(self.body)
end

function Lynx.dispatch(self: Lynx, req: Runtime.ServeRequest): Runtime.ServeResponse
	local match: MatchResponse? = Router.match(self.router, req.method, req.path)

	-- Set up LynxRequest. This should probably be a class eventually
	local lynxReq: LynxRequest = {
		path = req.path,
		query = req.query,
		method = req.method,
		headers = req.headers,
		body = req.body,
		params = {},
		valid = {},
		json = RequestJson,
	}
	local context = Context.new(lynxReq, self.notFoundHandler)

	if not match then
		return self.notFoundHandler(context)
	end

	if #match == 1 then
		local handler = match[1].handler
		context.req.params = match[1].params or {}
		local success, result = pcall(handler :: any, context, function()
			return self.notFoundHandler(context) -- If the single handler is a middleware, it must be not found
		end)

		if success then
			return (result :: Runtime.ServeResponse?) or context.res
		else
			return self.errorHandler(context, tostring(result))
		end
	end

	local function dispatch(i): Runtime.ServeResponse?
		if i > #match then
			return self.notFoundHandler(context)
		end

		context.req.params = match[i].params or {}

		local handler = match[i].handler

		return (handler :: Middleware)(context, function()
			dispatch(i + 1)
		end)
	end

	local success, result = pcall(dispatch, 1)

	if not success then
		return self.errorHandler(context, tostring(result))
	elseif context.finalized then
		return context.res
	else
		return self.notFoundHandler(context :: Context)
	end
end

function Lynx.request(self: Lynx, request: string | Runtime.ServeRequest): Runtime.ServeResponse
	if typeof(request) == "string" then
		return self:dispatch({
			method = "GET",
			path = request,
			body = "",
			headers = {},
			query = {},
		})
	end
	return self:dispatch(request)
end

function Lynx.serve(self: Lynx, config: LynxConfig?)
	local c: LynxConfig = config or {}
	self.server = Runtime.serve(c, function(req)
		return Lynx.dispatch(self, req)
	end)
	return self
end

return Lynx
