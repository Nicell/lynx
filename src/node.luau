local Node = {}
Node.__index = Node

export type Node = typeof(Node)

function Node.new()
  local self = setmetatable({}, Node)
  self.methods = {}
  self.children = {}
	self.order = 0
  self.name = ""
  self.params = {}
	self.wildcard = nil
  return self
end

function Node:insert(method: string, path: string, handler: () -> ())
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
      currentNode = currentNode.params[paramName]
    elseif part == "*" then
      if not currentNode.wildcard then
        currentNode.wildcard = Node.new()
        currentNode.wildcard.order = currentNode.order + 1
      end
      currentNode = currentNode.wildcard
    else
      if not currentNode.children[part] then
        currentNode.children[part] = Node.new()
        currentNode.children[part].order = currentNode.order + 1
      end
      currentNode = currentNode.children[part]
    end
  end

  if currentNode.methods[method] then
    error(`Handler already exists for {method} {path}`)
  end

  currentNode.methods[method] = {
    handler = handler,
    score = self.order,
  }
  currentNode.name = path
end

function Node:search(method: string, parts: { string }, params: { [string]: string}?): {{ params: { [string]: string }?, handler: () -> (), score: number }}
  local handlers = {}

  local p = parts[1]

  if p == nil then
    if self.methods[method] then
      table.insert(handlers, { params = params, handler = self.methods[method].handler, score = self.methods[method].score })
    end
    if self.methods["ALL"] then
      table.insert(handlers, { params = params, handler = self.methods["ALL"].handler, score = self.methods["ALL"].score })
    end
    if self.wildcard then
      if self.wildcard.methods[method] then
        table.insert(handlers, { params = params, handler = self.wildcard.methods[method].handler, score = self.wildcard.methods[method].score })
      elseif self.wildcard.methods["ALL"] then
        table.insert(handlers, { params = params, handler = self.wildcard.methods["ALL"].handler, score = self.wildcard.methods["ALL"].score })
      end
    end
    return handlers
  end

  local nextParts = {}
  table.move(parts, 2, #parts, 1, nextParts)

  if self.children[p] then
    local childHandlers = self.children[p]:search(method, nextParts, params)
    table.move(childHandlers, 1, #childHandlers, #handlers + 1, handlers)
  end

  for param, node in self.params do
    local newParams = if params then table.clone(params) else {}
    newParams[param] = p
    local childHandlers = node:search(method, nextParts, newParams)
    table.move(childHandlers, 1, #childHandlers, #handlers + 1, handlers)
  end

  if self.wildcard then
    local wildcardHandlers = self.wildcard:search(method, {}, params)
    table.move(wildcardHandlers, 1, #wildcardHandlers, #handlers + 1, handlers)
  end

  return handlers
end

return Node
