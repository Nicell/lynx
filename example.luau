local Lynx = require("@lynx")

local app = Lynx.new()

-- Middleware to calculate and attach response time
app:use(function(c, next)
	local start = os.clock()
	next()
	local time = os.clock() - start
	c:header("X-Response-Time", time)
end)

-- Send text response with a parameter and query string
app:get("/hello/:name", function(c)
	local name = c.req.params.name
	local last = c.req.query.last
	return c:text(`Hello, {name} {last or ""}!`)
end)

-- Send JSON response
app:get("/json", function(c)
	return c:json({ message = { "this", "is", "json!" } })
end)

-- Redirects /jason to /json
app:get("/jason", function(c)
	return c:redirect("/json")
end)

-- Get post body
app:post("/receive", function(c)
	return c:text("Got message: " .. c.req.body)
end)

-- Send HTML response
app:get("/html", function(c)
	return c:html("<h1>Hello, Lynx!</h1>")
end)

-- Serve static files
app:static("/static", "public")

-- 404 handler
app:notFound(function(c)
	return c:text(`🔍 {c.req.method} {c.req.path} Not found`, 404)
end)

-- Route a sub-app
local api = Lynx.new()

api:get("/hello", function(c)
	return c:text("Hello, API!")
end)

app:route("/api", api)

app:serve()
