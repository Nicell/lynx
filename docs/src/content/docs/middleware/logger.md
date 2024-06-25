---
title: Logger Middleware
sidebar:
  label: Logger
description: Log incoming request details.
---

Logger middleware logs incoming request details.

```luau
local Lynx = require("@lynx/lynx")
local logger = require("@lynx/middleware/logger")

local app = Lynx.new()

app:use(logger())
```

## Example Output

Each log contains a timestamp, status code, method, path, and response time.

```console
00:56:37 [302] GET /jason 1ms
00:56:37 [200] GET /json 0ms
00:56:52 [404] GET /hello/world 0ms
```

To disable colors in the log output, set the `NO_COLOR` environment variable.

## Custom Function

By default, the logger middleware uses `print` to log messages. You can provide a custom function to the logger middleware to log messages.

```luau
app:use(logger(function(msg)
  print("Custom Logger: " .. msg)
end))
```
