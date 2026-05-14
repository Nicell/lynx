# 🐈 Lynx

[**Documentation ⚡️ lynx.luau.page**](https://lynx.luau.page)

Lynx is a simple and fast Luau web framework for Lute and Lune. Lynx is inspired by [Hono](https://github.com/honojs/hono) and shares a similar API.

```luau
local app = Lynx.new()

app:get('/', function(c)
	return c:text('Lynx!')
end)

app:serve()
```

## Features

- 🧩 **Simple API** - Convenient methods for creating routes and generating a response
- ⚡️ **Fast Routing** - Efficient routing using a radix tree
- 📦 **Intuitive Middleware** - Extend request handling easily

## Documentation

Read the documentation at [lynx.luau.page](https://lynx.luau.page).
