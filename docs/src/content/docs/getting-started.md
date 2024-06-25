---
title: Getting Started
description: Get started with the Lynx Web Framework.
---

Lynx is a fast and simple Luau web framework for Lune. Lynx is inspired by [Hono](https://hono.dev) and shares a similar API.

```luau
local Lynx = require('@lynx')
local app = Lynx.new()

app:get('/', function(c)
  return c:text('Hello, Lynx!')
end)

app:serve()
```

## Installation

To install Lynx, add the repository as a submodule in your project.

```sh
git submodule add https://github.com/Nicell/lynx.git lynx
```

This will add Lynx to your project in the `lynx` directory.

To update Lynx, update the submodule from the remote.

```sh
git submodule update --remote
```

### Require Alias

To make requiring Lynx easier, you can add an alias to your project.

```json
// .luaurc
{
  "alias": {
    "lynx": "lynx/src"
  }
}
```

If you're using the [Luau LSP](https://github.com/JohnnyMorganz/luau-lsp) VSCode extension, you can add the alias to your `settings.json`.

```json
// .vscode/settings.json
{
  "luau-lsp.require.directoryAliases": {
    "@lynx": "lynx/src"
  }
}
```

Now you can require Lynx using the alias.

```luau
local Lynx = require('@lynx')
```

## Features

- 🧩 **Simple API** - Convenient methods for creating routes and generating a response
- ⚡️ **Fast Routing** - Efficient routing using a radix tree
- 📦 **Intuitive Middleware** - Extend request handling easily

## Use Cases

Lynx is a simple web framework that can be used for a variety of applications. It can be used for a simple web API, a proxy server, or it can be composed with other services.
