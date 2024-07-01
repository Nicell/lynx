---
title: Validation
description: Validate incoming requests in Lynx.
sidebar:
  order: 3
---

Lynx includes a validation middleware that allows you to validate incoming requests. You can validate the request JSON body, URL query, path parameters, and headers.

## Manual Validation

The validator middleware takes a function that returns a boolean and an optional error message. If the function returns `false`, the middleware will respond with a 400 status code and the error message.

After validation, the validated data is stored in the `req.valid` table.

```luau
local validator = require("@lynx/validator")
...
app:post("/validate", validator(function(value)
	if type(value) ~= "table" then
		return false, "Expected JSON object"
	end
	if not value.name then
		return false, "Missing 'name' field"
	end
	if not value.age then
		return false, "Missing 'age' field"
	end
	return true
end), function(c)
	local json = c.req.valid.json
	return c:text(`Hello, {json.name}! You are {json.age} years old.`)
end)
```

By default, the validator checks the JSON body. You can also validate the URL query, path parameters, or headers by using the optional first argument.

Validation targets: `json`, `query`, `params`, `headers`.

```luau
app:get("/validate", validator("query", function(value)
  if not value.name then
    return false, "Missing 'name' query parameter"
  end
  return true
end), function(c)
  local query = c.req.valid.query
  return c:text(`Hello, {query.name}!`)
end)
```

## Validation with t

[`t` is a runtime type-checking library for Luau](https://github.com/osyrisrblx/t). The functions returned by `t` can be used directly in the validator.

```luau
app:post("/validate", validate(t.interface({
    name = t.string,
    age = t.number,
})), function(c)
    local json = c.req.valid.json
    return c:text(`Hello, {json.name}! You are {json.age} years old.`)
end)
```

:::tip
You can install and use `t` by adding it as a git submodule, similarly to [how Lynx is installed](/getting-started#installation).

When defining the alias, use `t/lib` as the path.
:::

By using `t`, you'll get a more detailed error message when the validation fails.

```
POST /validate
  body: {}

> [interface] bad value for name:
    string expected, got nil
```

```
POST /validate
  body: {
    "name": "Ronald McDonald",
    "age": "59"
  }

> [interface] bad value for age:
    number expected, got string
```
