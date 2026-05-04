--!nocheck
local test = require("@std/test")
local router = require("./router")

local function handler(value: string)
	return function()
		return value
	end
end

local function values(matches)
	local result = {}
	for _, match in matches do
		table.insert(result, (match.handler :: any)())
	end
	return result
end

test.suite("router", function()
	test.case("matches static paths", function(asserts)
		local r = router.new()
		r:add("GET", "/hello", handler("hello"))

		local res = r:match("GET", "/hello")

		asserts.neq(res, nil)
		asserts.eq(res[1].handler(), "hello")
	end)

	test.case("does not match a route registered for another method", function(asserts)
		local r = router.new()
		r:add("POST", "/hello", handler("post"))

		local res = r:match("GET", "/hello")

		asserts.neq(res, nil)
		asserts.eq(#res, 0)
	end)

	test.case("matches ALL handlers alongside method-specific handlers in insertion order", function(asserts)
		local r = router.new()
		r:add("ALL", "/hello", handler("all first"))
		r:add("GET", "/hello", handler("get second"))
		r:add("ALL", "/hello", handler("all third"))

		local res = r:match("GET", "/hello")

		asserts.eq(values(res), { "all first", "get second", "all third" })
	end)

	test.case("extracts multiple named parameters", function(asserts)
		local r = router.new()
		r:add("GET", "/teams/:teamId/users/:userId", handler("user"))

		local res = r:match("GET", "/teams/red/users/42")

		asserts.eq(res[1].params, {
			teamId = "red",
			userId = "42",
		})
	end)

	test.case("matches wildcard suffixes across multiple remaining path parts", function(asserts)
		local r = router.new()
		r:add("GET", "/assets/*", handler("asset"))

		local onePart = r:match("GET", "/assets/logo.png")
		local multipleParts = r:match("GET", "/assets/images/icons/logo.png")

		asserts.eq(onePart[1].handler(), "asset")
		asserts.eq(multipleParts[1].handler(), "asset")
	end)

	test.case("matches wildcard path segments one level when followed by static parts", function(asserts)
		local r = router.new()
		r:add("GET", "/wild/*/card", handler("card"))

		local match = r:match("GET", "/wild/one/card")
		local miss = r:match("GET", "/wild/one/two/card")

		asserts.eq(match[1].handler(), "card")
		asserts.neq(miss, nil)
		asserts.eq(#miss, 0)
	end)

	test.case("keeps route definition order across static param and wildcard matches", function(asserts)
		local r = router.new()
		r:add("GET", "/items/*", handler("wildcard first"))
		r:add("GET", "/items/:id", handler("param second"))
		r:add("GET", "/items/exact", handler("static third"))

		local res = r:match("GET", "/items/exact")

		asserts.eq(values(res), { "wildcard first", "param second", "static third" })
	end)

	test.case("returns nil for paths that do not match any route shape", function(asserts)
		local r = router.new()
		r:add("GET", "/hello", handler("hello"))

		local res = r:match("GET", "/goodbye")

		asserts.eq(res, nil)
	end)
end)
