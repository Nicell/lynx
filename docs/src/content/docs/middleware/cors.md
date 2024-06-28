---
title: CORS Middleware
sidebar:
  label: CORS
description: Enable Cross-Origin Resource Sharing.
---

CORS middleware enables Cross-Origin Resource Sharing for your application.

```luau
local Lynx = require("@lynx/lynx")
local cors = require("@lynx/middleware/cors")

local app = Lynx.new()

app:use(cors())
```

## Options

You can provide options to the CORS middleware.

```luau
app:use(cors({
  origin = "*",
  methods = { "GET", "POST" },
}))
```

Full list of options:

- `origin`: `string | {string} | (origin: string) -> string`
  - The value of the `Access-Control-Allow-Origin` header. A table of origins or a callback function can also be used. Default: `*`.
- `methods`: `{string}?`
  - The value of the `Access-Control-Allow-Methods` header. Default: `{"GET", "HEAD", "PUT", "PATCH", "POST", "DELETE"}`.
- `allowHeaders`: `{string}?`
  - The value of the `Access-Control-Allow-Headers` header.
- `exposeHeaders`: `{string}?`
  - The value of the `Access-Control-Expose-Headers` header.
- `maxAge`: `number?`
  - The value of the `Access-Control-Max-Age` header. Represents the number of seconds the preflight request can be cached.
- `credentials`: `boolean?`
  - The value of the `Access-Control-Allow-Credentials` header.
