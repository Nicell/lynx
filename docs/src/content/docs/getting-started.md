---
title: Getting Started
description: Get started with the Lynx Web Framework.
---

Lynx is a fast and simple web framework for [Lune](https://github.com/lune-org/lune), a general purpose runtime for the [Luau programming language](https://luau.org). Lynx is inspired by [Hono](https://hono.dev/) and shares a similar API.

## Basic usage

```luau
local Lynx = require("@lynx/lynx")
local app = Lynx.new()

app:get("/", function(c)
  return c:text("Hello, Lynx!")
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

### Editor setup and require aliases

To make importing Lynx easier, you can add a `.luaurc` require alias to your project:

```json
// .luaurc
{
  "aliases": {
    "lynx": "lynx/src/"
  }
}
```

It's recommended to use the [Luau LSP](https://github.com/JohnnyMorganz/luau-lsp) VSCode extension. This should give you inline autocompletion, inline documentation, and type-hinting support in your editor.

#### If you encounter "invalid require" TypeErrors or other issues when trying to require Lynx, try:
- closing and re-opening your `.luau` files,
- making sure you've opened the current folder as a VSCode workspace,
- checking your `.luaurc` for syntax, spelling, invalid whitespaces and/or missing trailing slashes (sometimes can cause platform-specific issues),
- and restarting the Luau LSP extension. 

### Using Lynx in your project
Now you can require Lynx using the alias `"@lynx/lynx"`:

```luau
-- main.luau (or any other location in your project)
local Lynx = require("@lynx/lynx") -- hover over the Lynx variable for inline documentation
```

## Features

- 🧩 **Simple API** - Convenient methods for creating routes and generating a response
- ⚡️ **Fast Routing** - Efficient routing using a radix tree
- 📦 **Intuitive Middleware** - Extend request handling easily

## Use cases
Lynx can be used to write a simple web API, a quick-and-easy simple html website, a proxy server, or to glue other web services together for extra potential!
