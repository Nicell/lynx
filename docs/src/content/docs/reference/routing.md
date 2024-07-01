---
title: Routing
description: Learn how to route requests in Lynx.
sidebar:
  order: 2
---

Routing is simple and powerful in Lynx.

## Basic

```luau
app:get("/", function(c)
  return c:text("Hello, Lynx!")
end)

-- Match all methods
app:all("/all", function(c)
  return c:text("All methods")
end)

-- Match a custom method
app:on("LIT", "/", function(c)
  return c:text("Custom method")
end)
```

```
GET  /    -> Hello, Lynx!
GET  /all -> All methods
POST /all -> All methods
LIT  /    -> Custom method
```

## Parameters

Paths can contain named parameters that are extracted from the URL.

```luau
app:get("/hello/:name", function(c)
  local name = c.req.params.name
  return c:text("Hello, " .. name .. "!")
end)
```

```
GET /hello/Dave -> Hello, Dave!
```

You can have multiple parameters in a path.

```luau
app:get("/hello/:first/:last", function(c)
  local first = c.req.params.first
  local last = c.req.params.last
  return c:text("Hello, " .. first .. " " .. last .. "!")
end)
```

```
GET /hello/Dave/Baszucki -> Hello, Dave Baszucki!
```

## JSON

JSON can be retrieved from the request body.

```luau
app:post("/json", function(c)
  local body = c.req:json()
  return c:json(body)
end)
```

## Wildcards

Wildcards can be used to match multiple paths. When placed at the end of a path, it matches any path that starts with the prefix.

```luau
app:get("/hello/*", function(c)
  return c:text("Hello, Wildcard!")
end)
```

```
GET /hello/world       -> Hello, Wildcard!
GET /hello/world/again -> Hello, Wildcard!
```

If you don't need a named parameter, you can use a wildcard instead. It only matches one level.

```luau
app:get("/wild/*/card", function(c)
  return c:text("Hello, Wildcard!")
end)
```

```
GET /wild/one/card    -> Hello, Wildcard!
GET /wild/one/two/card -> 404 Not Found
```

## Grouping

Routes can be grouped in sub-apps and then routed on the main app.

```luau
local api = Lynx.new()

api:get("/hello", function(c)
  return c:text("Hello, API!")
end)

app:route("/api", api)
```

```
GET /api/hello -> Hello, API!
```

## Middleware

Middleware can be used to modify the context before or after the handler is executed.

```luau
app:use(function(c, next)
  c:header("X-Request-Id", "123")
  next()
end)
```

If you don't specify, it's applied to all routes. It can be applied to a specific path.

```luau
app:use("/admin/*", function(c, next)
  if not c.req.headers["authorization"] then
    return c:status(401):text("Unauthorized")
  end
  next()
end)
```

Middleware can also modify the response after the handler is executed.

```luau
app:use(function(c, next)
  local start = os.clock()
  next()
  local time = os.clock() - start
  c:header("X-Response-Time", time)
end)
```

## Priority

Handlers and middleware are executed in the order they are defined.

```luau
app:get("/hello/world", function(c)
  return c:text("Hello, World!")
end)

app:get("/hello/:name", function(c)
  return c:text("Hello, stranger!")
end)
```

```
GET /hello/world -> Hello, World!
GET /hello/other -> Hello, stranger!
```

Once the first handler is executed, no more handlers are executed for that request.

```luau
app:get("/*", function(c)
  return c:text("Defined first")
end)

app:get("/two", function(c)
  return c:text("Defined second")
end)
```

```
GET /one -> Defined first
GET /two -> Defined first
```

Middleware must be defined before the handler it applies to.

```luau
app:use(function(c, next)
  local start = os.clock()
  next()
  local time = os.clock() - start
  c:header("X-Response-Time", time)
end)

app:get("/time", function(c)
  return c:text("Response time")
end)
```

```
GET /time -> Response time with X-Response-Time header
```
