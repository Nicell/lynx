local Node = require("node")
type Node = Node.Node

local Router = {}
Router.__index = Router

export type Router = typeof(setmetatable(
	{} :: {
		node: Node,
	},
	Router
))

function Router.new(): Router
	local self = setmetatable({}, Router)
	self.node = Node.new()
	return self
end

function Router.add(self: Router, method: string, path: string, handler: (...any) -> ...any)
	self.node:insert(method, path, handler)
end

function Router.match(self: Router, method: string, path: string)
	local parts = path:sub(2):split("/")

	local handlers = self.node:search(method, parts, 1)

	if handlers then
		table.sort(handlers, function(a, b)
			return a.score < b.score
		end)
	end

	return handlers
end

return Router
