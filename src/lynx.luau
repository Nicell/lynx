local net = require("@lune/net")
local Router = require("router")
local Context = require("context")
local static = require("static")

type Router = Router.Router
type Context = Context.Context
type LynxRequest = Context.LynxRequest
export type Handler = (c: Context) -> net.ServeResponse
export type ErrorHandler = (c: Context, error: string) -> net.ServeResponse
export type Middleware = (c: Context, next: () -> ()) -> ()
export type MatchResponse = { { params: { [string]: string }?, handler: Handler | Middleware, score: number } }

-- Luau unions are rough, so we need to define a mixed handler type instead of using Handler | Middleware
type MixedHandler = (c: Context, next: () -> ()) -> () | net.ServeResponse

local Lynx = {}
Lynx.__index = Lynx

export type Lynx = typeof(setmetatable(
	{} :: {
		router: Router,
		routes: { { method: string, path: string, handler: Handler | Middleware } },
		notFoundHandler: Handler,
		errorHandler: ErrorHandler,
		server: net.ServeHandle?,
	},
	Lynx
))
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

function Lynx.new(): Lynx
	local self = setmetatable({}, Lynx)
	self.router = Router.new()
	self.routes = {}
	self.notFoundHandler = defaultNotFound
	self.errorHandler = defaultErrorHandler
	return self
end

function Lynx.route(self: Lynx, path: string, app: Lynx)
	for _, route in app.routes do
		self:addRoute(route.method, path .. route.path, route.handler)
	end
	return self
end

function Lynx.addRoute(self: Lynx, method: string, path: string, handler: Handler | Middleware | MixedHandler)
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

	self.router:add("ALL", realPath :: string, handler :: Middleware)
	for _, h in { ... } do
		self.router:add("ALL", realPath :: string, h)
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

function Lynx.onError(self: Lynx, handler: Handler)
	self.errorHandler = handler
	return self
end

function RequestJson(self: LynxRequest)
	return net.jsonDecode(self.body)
end

function Lynx.dispatch(self: Lynx, req: net.ServeRequest): net.ServeResponse
	local match: MatchResponse = Router.match(self.router, req.method, req.path)

	-- Set up LynxRequest. This should probably be a class eventually
	local lynxReq: LynxRequest = req :: LynxRequest
	lynxReq.params = {}
	lynxReq.valid = {}
	lynxReq.json = RequestJson
	local context = Context.new(lynxReq, self.notFoundHandler)

	if not match then
		return self.notFoundHandler(context)
	end

	if #match == 1 then
		local handler = match[1].handler
		context.req.params = match[1].params or {}
		local success, result = pcall(handler, context, function()
			return self.notFoundHandler(context) -- If the single handler is a middleware, it must be not found
		end)

		if success then
			return result or context.res
		else
			return self.errorHandler(context, (result :: unknown) :: string)
		end
	end

	local function dispatch(i): net.ServeResponse?
		if i > #match then
			return self.notFoundHandler(context)
		end

		context.req.params = match[i].params or {}

		local handler = match[i].handler

		return handler(context, function()
			dispatch(i + 1)
		end)
	end

	local success, result = pcall(dispatch, 1)

	if not success then
		return self.errorHandler(context, (result :: unknown) :: string)
	elseif context.finalized then
		return context.res
	else
		return self.notFoundHandler(context)
	end
end

function Lynx.request(self: Lynx, request: string | net.ServeRequest): net.ServeResponse
	if type(request) == "string" then
		request = {
			method = "GET",
			path = request,
		} :: net.ServeRequest
	end
	return self:dispatch(request :: net.ServeRequest)
end

function Lynx.serve(self: Lynx, config: LynxConfig?)
	local c: LynxConfig = config or {}
	self.server = net.serve(c.port or 3000, {
		address = c.address or "http://0.0.0.0",
		handleRequest = function(req)
			return Lynx.dispatch(self, req)
		end,
	})
	return self
end

return Lynx
