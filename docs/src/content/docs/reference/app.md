---
title: App
description: The main application class.
sidebar:
  order: 1
---

The `Lynx` class is used to create your application.

```luau
local Lynx = require("@lynx/lynx")

local app = Lynx.new()

-- Define routes and middleware here

app:serve()
```

:::tip
For details on path routing, see the [Routing](/reference/routing) page.
:::

## Methods

### `:<method>`

`:<method>(path: string, handler: Handler)`

Supported methods: `:get`, `:post`, `:put`, `:delete`, `:patch`

Define a route for a specific HTTP method.

```luau
app:get("/", function(c)
  return c:text("Hello, Lynx!")
end)
```

### `:all`

`:all(path: string, handler: Handler)`

Define a route that matches all HTTP methods.

```luau
app:all("/all", function(c)
  return c:text("All methods")
end)
```

### `:on`

`:on(method: string, path: string, handler: Handler)`

Define a route for a specific or custom HTTP method.

```luau
app:on("CUSTOM", "/custom", function(c)
  return c:text("Custom method")
end)
```

### `:use`

`:use(middleware: Middleware)` or `:use(path: string, middleware: Middleware)`

Create a middleware that runs on every request or on a specific path.

```luau
app:use(function(c, next)
  print("Before request")
  next()
  print("After request")
end)
```

### `:static`

`:static(path: string, directory: string)`

Serve static files from a directory.

```luau
app:static("/static", "public")
```

### `:route`

`:route(path: string, app: Lynx)`

Mount a sub-application at a specific path.

```luau
local api = Lynx.new()

api:get("/", function(c)
  return c:text("api")
end)

app:route("/api", api)
```

### `:notFound`

`:notFound(handler: Handler)`

Define a custom 404 handler.

```luau
app:notFound(function(c)
	return c:text(`🔍 {c.req.method} {c.req.path} Not found`, 404)
end)
```

### `:onError`

`:onError(handler: ErrorHandler)`

Define a custom error handler.

```luau
app:onError(function(c, err)
  return c:text(`🚨 {err}`, 500)
end)
```

### `:request`

`:request(request: string | net.ServeRequest)`

Send a request to the application and return the response. This can be useful for testing your application.

```luau
local response = app:request("/hello")
```

Alternatively, you can pass a `net.ServeRequest` object.

```luau
local response = app:request({
  method = "POST",
  path = "/create"
})
```

### `:serve`

`:serve(port: number?)`

Start serving the application. Optionally specify a port *(default: 3000)*.

```luau
app:serve()
```
