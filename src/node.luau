local Types = require("./types")

local Node = {}
Node.__index = Node

type MatchResponse = Types.MatchResponse
type Handler = Types.Handler
type Middleware = Types.Middleware

type NodeData = {
	methods: { [string]: { { handler: Handler | Middleware, score: number } } },
	children: { [string]: Node },
	order: number,
	name: string,
	params: { [string]: Node },
	wildcard: Node?,
}

export type Node = typeof(setmetatable({} :: NodeData, Node))

function Node.new(): Node
	local self = {}
	self.methods = {}
	self.children = {}
	self.order = 0
	self.name = ""
	self.params = {}
	self.wildcard = nil :: Node?
	return setmetatable(self, Node)
end

function Node.insert(self: Node, method: string, path: string, handler: Handler | Middleware)
	local currentNode = self
	local parts = path:split("/")
	self.order += 1
	if parts[1] == "" then
		table.remove(parts, 1)
	end

	for _, part in parts do
		if part:sub(1, 1) == ":" then
			local paramName = part:sub(2)
			if not currentNode.params[paramName] then
				currentNode.params[paramName] = Node.new()
				currentNode.params[paramName].order = currentNode.order + 1
			end
			currentNode = currentNode.params[paramName] :: Node
		elseif part == "*" then
			if not currentNode.wildcard then
				currentNode.wildcard = Node.new()
				currentNode.wildcard.order = currentNode.order + 1
			end
			currentNode = currentNode.wildcard :: Node
		else
			if not currentNode.children[part] then
				currentNode.children[part] = Node.new()
				currentNode.children[part].order = currentNode.order + 1
			end
			currentNode = currentNode.children[part] :: Node
		end
	end

	if not currentNode.methods[method] then
		currentNode.methods[method] = {}
	end

	table.insert(currentNode.methods[method], {
		handler = handler,
		score = self.order,
	})
	currentNode.name = path
end

function Node.getHandlers(self: Node, method: string, params: { [string]: string }?)
	local handlers = {}

	if self.methods[method] then
		for _, entry in self.methods[method] do
			table.insert(handlers, {
				params = params,
				handler = entry.handler,
				score = entry.score,
			})
		end
	end
	if self.methods["ALL"] then
		for _, entry in self.methods["ALL"] do
			table.insert(handlers, {
				params = params,
				handler = entry.handler,
				score = entry.score,
			})
		end
	end
	if self.wildcard then
		if self.wildcard.methods[method] then
			for _, entry in self.wildcard.methods[method] do
				table.insert(handlers, {
					params = params,
					handler = entry.handler,
					score = entry.score,
				})
			end
		end
		if self.wildcard.methods["ALL"] then
			for _, entry in self.wildcard.methods["ALL"] do
				table.insert(handlers, {
					params = params,
					handler = entry.handler,
					score = entry.score,
				})
			end
		end
	end
	return handlers
end

function Node.search(
	self: Node,
	method: string,
	parts: { string },
	depth: number,
	params: { [string]: string }?
): MatchResponse?
	local p = parts[depth]

	if not p then
		return Node.getHandlers(self, method, params)
	end

	local handlers: MatchResponse? = nil

	if self.children[p] then
		handlers = Node.search(self.children[p], method, parts, depth + 1, params)
	end

	for param, node in self.params do
		local newParams: { [string]: string } = if params then table.clone(params) else {}
		newParams[param] = p
		local paramHandlers = Node.search(node, method, parts, depth + 1, newParams)
		if paramHandlers then
			if handlers then
				table.move(paramHandlers, 1, #paramHandlers, #handlers + 1, handlers)
			else
				handlers = paramHandlers
			end
		end
	end

	if self.wildcard then
		local wildcardHandlers = Node.search(self.wildcard, method, parts, depth + 1, params)
		if depth + 1 <= #parts then -- Search is still ongoing, check for direct wildcard handlers
			local directHandlers = Node.getHandlers(self :: Node, method, params)
			if wildcardHandlers then
				table.move(directHandlers, 1, #directHandlers, #wildcardHandlers + 1, wildcardHandlers)
			else
				wildcardHandlers = directHandlers
			end
		end
		if wildcardHandlers then
			if handlers then
				table.move(wildcardHandlers, 1, #wildcardHandlers, #handlers + 1, handlers)
			else
				handlers = wildcardHandlers
			end
		end
	end

	return handlers
end

return Node
