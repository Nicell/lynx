local serde = require("@lune/serde")
local Context = require("../context")
type Context = Context.Context

local ENCODINGS: { { name: string, encode: serde.CompressDecompressFormat } } = {
	{
		name = "br",
		encode = "brotli",
	},
	{
		name = "gzip",
		encode = "gzip",
	},
}

local function compress()
	return function(c: Context, next: () -> ())
		next()
		local acceptEncoding = c.req.headers["accept-encoding"]
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
		c.res.body = serde.compress(encoding.encode, c.res.body)
	end
end

return compress
