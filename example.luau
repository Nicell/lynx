local Lynx = require("@lynx/lynx")
local validator = require("@lynx/validator")

local app = Lynx.new()

-- Middleware to calculate and attach response time
app:use(function(c, next)
	local start = os.clock()
	next()
	local time = os.clock() - start
	c:header("X-Response-Time", tostring(time))
end)

-- Send text response with a parameter and query string
app:get("/hello/:name", function(c)
	local name = c.req.params.name
	local last = c.req.query.last
	return c:text(`Hello, {name} {last or ""}!`)
end)

-- Validate JSON request body
app:post("/validate", validator(function(value)
	if type(value) ~= "table" then
		return false, "Expected JSON object"
	end
	if not value.name then
		return false, "Missing 'name' field"
	end
	if not value.age then
		return false, "Missing 'age' field"
	end
	return true
end), function(c)
	local json = c.req.valid.json
	return c:text(`Hello, {json.name}! You are {json.age} years old.`)
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
