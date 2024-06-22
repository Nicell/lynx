local Node = require("node")

local Router = {}
Router.__index = Router

export type Router = typeof(Router)

function Router.new()
	local self = setmetatable({}, Router)
	self.node = Node.new()
	return self
end

function Router:add(method: string, path: string, handler: () -> ())
	self.node:insert(method, path, handler)
end

function Router:match(method: string, path: string)
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
