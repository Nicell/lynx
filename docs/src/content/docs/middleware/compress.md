---
title: Compression Middleware
sidebar:
  label: Compress
description: Compress response bodies.
---

Compression middleware compresses response bodies before sending them to the client.

The compression algorithm is determined by the client's `Accept-Encoding` header. `br` (Brotli) and `gzip` are supported and are selected in that order.

Compression depends on runtime support. Lune supports Brotli and gzip through its serde APIs. Lute does not currently provide compression APIs, so this middleware leaves responses uncompressed when Lynx is running on Lute.

```luau
local Lynx = require("@lynx/lynx")
local compress = require("@lynx/middleware/compress")

local app = Lynx.new()

app:use(compress())
```
