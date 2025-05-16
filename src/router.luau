local Node = require("./node")
type Node = Node.Node

local Types = require("./types")
type Handler = Types.Handler
type Middleware = Types.Middleware

local Router = {}
Router.__index = Router

type RouterData = {
	node: Node,
}

export type Router = typeof(setmetatable({} :: RouterData, Router))

function Router.new(): Router
	local self = {}
	self.node = Node.new()
	return setmetatable(self, Router)
end

function Router.add(self: Router, method: string, path: string, handler: Handler | Middleware)
	self.node:insert(method, path, handler)
end

function Router.match(self: Router, method: string, path: string)
	local parts = string.split(string.sub(path, 2), "/")

	local handlers = Node.search(self.node, method, parts, 1)

	if handlers then
		table.sort(handlers, function(a, b)
			return a.score < b.score
		end)
	end

	return handlers
end

return Router
