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
	local parts = path:split("/")
	if parts[1] == "" then
		table.remove(parts, 1)
	end

	local search = self.node:search(method, parts)

	table.sort(search, function(a, b)
		return a.score < b.score
	end)

	local handlers = {}

	for _, s in search do
		table.insert(handlers, { params = s.params or {}, handler = s.handler })
	end

  return handlers
end

return Router
