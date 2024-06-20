local Lynx = require("src/lynx")

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

app:serve()
