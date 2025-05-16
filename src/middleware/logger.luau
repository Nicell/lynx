local datetime = require("@lune/datetime")
local process = require("@lune/process")
local Context = require("../context")
type Context = Context.Context
local Types = require("@lynx/types")
type Middleware = Types.Middleware

local color = if process.env.NO_COLOR then false else true

local function dim(string: string): string
	if not color then
		return string
	end
	return `\x1b[2m{string}\x1b[0m`
end

local function statusColor(code: number?): string
	if not code then
		return "[???]"
	end
	local c = `[{code}]`
	if not color then
		return c
	end
	if code >= 500 then
		return `\x1b[31m{c}\x1b[0m` -- red
	elseif code >= 400 then
		return `\x1b[33m{c}\x1b[0m` -- yellow
	elseif code >= 300 then
		return `\x1b[36m{c}\x1b[0m` -- cyan
	end
	return `\x1b[32m{c}\x1b[0m` -- green
end

local function logger(func: (string) -> ()?)
	local fn: (string) -> () = func or print
	return function(c: Context, next: () -> ())
		local start = os.clock()
		next()
		local time = datetime.now():formatLocalTime("%H:%M:%S")
		local status = c.res.status
		local method = c.req.method
		local path = c.req.path
		local elapsedMs = (os.clock() - start) * 1000
		local elapsedFormatted = if elapsedMs > 1000
			then math.round(elapsedMs / 1000) .. "s"
			else math.round(elapsedMs) .. "ms"

		fn(`{dim(time)} {statusColor(status)} {method} {path} {dim(elapsedFormatted)}`)
	end
end

return logger :: Middleware
