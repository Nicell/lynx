---
title: Context
description: The request context object in Lynx.
sidebar:
  order: 3
---

The `Context` object is passed to route handlers and middleware functions. It contains information about the request and provides methods for generating a response.

## Properties

### `req`

The request object. Contains information about the incoming request. This table extends the [Lune ServeRequest](https://lune-org.github.io/docs/api-reference/net#serverequest) with the following:

- `params`: `{ [string]: string }`
  - Path parameters extracted from the route path.
- `valid`: `{ [string]: any }`
  - Validated data from the request. This table is populated by the [validator](/reference/validation).
- `:json()`:
  - Parse the request body as JSON.

```luau
app:get("/hello/:name", function(c)
  local name = c.req.params.name
  local last = c.req.query.last
  return c:text(`Hello, {name} {last or ""}!`)
end)
```

### `res`

The response object. Contains information about the response to be sent. This table is an instance of the [Lune ServeResponse](https://lune-org.github.io/docs/api-reference/net#serveresponse).

:::warning
Avoid modifying the response object directly. Use the `Context` methods instead.
:::

## Methods

### `:body`

`:body(body: buffer | string, status: number?, headers: any?)`

Send the response. Attach a body and optional status code and headers.

:::tip
In most cases, you should use the `:text`, `:json`, or `:html` methods instead of `:body`.
:::

```luau
app:get("/hello", function(c)
  return c:body("Hello, Lynx!", 200, { ["Content-Type"] = "text/plain" })
end)
```

### `:text`

`:text(body: string, status: number?, headers: any?)`

Send a text response. Attach a body and optional status code and headers.

```luau
app:get("/hello", function(c)
  return c:text("Hello, Lynx!")
end)
```

### `:json`

`:json(body: any, status: number?, headers: any?)`

Send a JSON response. Attach a body and optional status code and headers.

```luau
app:get("/json", function(c)
  return c:json({ message = { "this", "is", "json!" } })
end)
```

### `:html`

`:html(body: string, status: number?, headers: any?)`

Send an HTML response. Attach a body and optional status code and headers.

```luau

app:get("/html", function(c)
  return c:html("<h1>Hello, Lynx!</h1>")
end)
```

### `:header`

`:header(name: string, value: string)`

Set a response header.

```luau
app:get("/header", function(c)
  c:header("X-Header", "Value")
  return c:text("Header set")
end)
```

### `:status`

`:status(status: number)`

Set the response status code.

```luau
app:get("/create", function(c)
  c:status(201)
  return c:text("Created!")
end)
```

### `:redirect`

`:redirect(url: string, status: number?)`

Redirect to a URL. Attach an optional status code *(default 302)*.

```luau
app:get("/jason", function(c)
  return c:redirect("/json")
end)
```

### `:notFound`

`:notFound()`

Send the 404 response defined in the app.

```luau
app:get("/search", function(c)
  local reults = search(c.req.query.q)
  if results then
    return c:json(results)
  end
  return c:notFound()
end)
```

### `:set` / `:get`

`:set(key: string, value: any)`

`:get(key: string): any`

Set and get values on the context object. Useful for sharing data between middleware and route handlers.

```luau
app:use(function(c, next)
  c:set("user", getUser(c.req.headers.authorization))
  next()
end)

app:get("/profile", function(c)
  local user = c:get("user")
  return c:json(user)
end)
```
