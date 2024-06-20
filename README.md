# 🐈 Lynx

Lynx is a simple and fast Luau web framework for Lune. Lynx is inspired by [Hono](https://github.com/honojs/hono) and shares a similar API.

```lua
local app = Lynx.new()

app:get('/', function(c)
  return c:text('Lynx!')
end)

app:serve()
```

## Features

### Parameters

Route parameters and query parameters are supported.

```lua
app:get("/hello/:name", function(c)
  local name = c.req.params.name
  local last = c.req.query.last
	return c:text(`Hello, {name} {last or ""}!`)
end)
-- GET /hello/Dave?last=Baszucki
-- > Hello, Dave Baszucki!
```

### JSON

JSON responses are supported.

```lua
app:get("/json", function(c)
  return c:json({ message = { "this", "is", "json!" } })
end)
-- GET /json
-- > {"message":["this","is","json!"]}
```

### Middleware

Middleware can be easily added with `app:use`.

```lua
-- Adds a response time header to every request
app:use(function(c, next)
  local start = os.clock()
  next()
  local time = os.clock() - start
  c:header("X-Response-Time", time)
end)
```

### HTML

HTML responses are supported.

```lua
app:get("/html", function(c)
  return c:html("<h1>Hello, Lynx!</h1>")
end)
```

### Serve Static Files

Static files can be served with `app:static`.

```lua
app:static("/static", "public")
-- GET /static
-- > Serves the file at public/index.html
```

### Redirects

Redirects are supported.

```lua
app:get("/jason", function(c)
	return c:redirect("/json")
end)
-- GET /jason
-- > Redirected to /json
```

### Post Requests

Post requests (and all other HTTP methods) are supported.

```lua
app:post("/receive", function(c)
  return c:text("Got message: " .. c.req.body)
end)
-- POST /receive { body: "Hello, Lynx!" }
-- > Got message: Hello, Lynx!
```

## Implementation Details

Lynx currently uses a radix tree for routing. This is a simple and efficient way to match routes.

In terms of performance, Lynx performs slightly better than Express.

```
Lynx:
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    49.06us   64.23us   2.53ms   98.05%
    Req/Sec    22.22k     2.58k   23.75k    92.16%

Express:
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    79.94us  119.32us   3.54ms   96.25%
    Req/Sec    15.34k     2.00k   16.89k    84.31%

Lynx is 1.45x faster than Express.
```
