local net = require("@lune/net")
local Context = require("@lynx/context")
type Context = Context.Context
local Types = require("@lynx/types")
type Middleware = Types.Middleware

type ValidationTarget = "json" | "query" | "params" | "headers"
type ValidationFunction = (value: any) -> (boolean, string?)

local function validator(target: ValidationTarget | ValidationFunction, validation: ValidationFunction?): Middleware
  if type(target) == "function" then
    validation = target
    target = "json"
  end
  local targ = target
  local func = validation
  assert(type(func) == "function", "Validation function must be provided")

  return function(c: Context, next: () -> ()): net.ServeResponse?
    local value
    if targ == "json" then
      local success, json = pcall(c.req.json, c.req)
      if not success then
        return c:status(400):text("Invalid JSON")
      end
      value = json
    elseif targ == "query" then
      value = c.req.query
    elseif targ == "params" then
      value = c.req.params
    elseif targ == "headers" then
      value = c.req.headers
    end

    local valid, err = func(value)

    if not valid then
      return c:status(400):text(err or "Invalid request")
    end

    c.req.valid[targ] = value

    next()
    return nil -- TODO: How can we allow returning nothing?
  end
end

return validator
