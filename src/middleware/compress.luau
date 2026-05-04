local Runtime = require("../runtime")
local Context = require("../context")
type Context = Context.Context

local ENCODINGS: { { name: string, encode: string } } = {
	{
		name = "br",
		encode = "brotli",
	},
	{
		name = "gzip",
		encode = "gzip",
	},
}

local warnedUnsupported = false

local function compress()
	local compressor = Runtime.compress
	if not compressor then
		if not warnedUnsupported then
			print(`{Runtime.runtime} doesn't support compression and will be skipped`)
			warnedUnsupported = true
		end

		return function(_c: Context, next: () -> ())
			next()
		end
	end

	return function(c: Context, next: () -> ())
		next()
		local acceptEncoding = c.req.headers["accept-encoding"]
		if not acceptEncoding then
			return
		end

		local encoding
		for _, type in ENCODINGS do
			if acceptEncoding:find(type.name) then
				encoding = type
				break
			end
		end
		if not encoding or not c.res.body then
			return
		end
		c:header("Content-Length", nil)
		c:header("Content-Encoding", encoding.name)
		c.res.body = compressor(encoding.encode, c.res.body)
	end
end

return compress
