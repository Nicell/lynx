---
title: Compress Middleware
sidebar:
  label: Compress
description: Compress response bodies.
---

Compression middleware compresses response bodies before sending them to the client.

The compression algorithm is determined by the client's `Accept-Encoding` header. `br` (Brotli) and `gzip` are supported and are selected in that order.

```luau
local Lynx = require("@lynx/lynx")
local compress = require("@lynx/middleware/compress")

local app = Lynx.new()

app:use(compress())
```
