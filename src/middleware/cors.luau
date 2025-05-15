local net = require("@lune/net")
local Context = require("../context")
type Context = Context.Context
local Types = require("@lynx/types")
type Middleware = Types.Middleware

export type Options = {
  origin: string | {string} | (origin: string) -> string?,
  methods: {string}?,
  allowHeaders: {string}?,
  exposeHeaders: {string}?,
  maxAge: number?,
  credentials: boolean?,
}

local defaultOptions: Options = {
  origin = "*",
  methods = {"GET", "HEAD", "PUT", "PATCH", "POST", "DELETE"},
}

local function cors(options: Options?): Middleware
  local opts = table.clone(options or defaultOptions)
  if options then
    opts.origin = options.origin or defaultOptions.origin
    opts.methods = options.methods or defaultOptions.methods
  end

  local getOrigin: (string) -> string?

  if type(opts.origin) == "string" then
    getOrigin = function(origin: string)
      return if opts.origin == origin then origin else nil
    end
  elseif type(opts.origin) == "table" then
    getOrigin = function(origin: string): string?
      if table.find(opts.origin, origin) then
        return origin
      end
      return nil
    end
  else
    getOrigin = opts.origin
  end

  return function(c: Context, next: () -> ()): net.ServeResponse?
    local origin = c.req.headers["origin"]
    c:header("Access-Control-Allow-Origin", getOrigin(origin or ""))

    if opts.credentials then
      c:header("Access-Control-Allow-Credentials", "true")
    end

    if opts.exposeHeaders and #opts.exposeHeaders > 0 then
      c:header("Access-Control-Expose-Headers", table.concat(opts.exposeHeaders, ","))
    end

    if c.req.method == "OPTIONS" then
      if opts.maxAge then
        c:header("Access-Control-Max-Age", tostring(opts.maxAge))
      end

      if opts.methods and #opts.methods > 0 then
        c:header("Access-Control-Allow-Methods", table.concat(opts.methods, ","))
      end

      if opts.allowHeaders and #opts.allowHeaders > 0 then
        c:header("Access-Control-Allow-Headers", table.concat(opts.allowHeaders, ","))
      else
        c:header("Access-Control-Allow-Headers", c.req.headers["access-control-request-headers"])
      end

      return c:status(204):finalize()
    end
    next()
		return nil -- TODO: How can we allow returning nothing?
  end
end

return cors
