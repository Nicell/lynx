--!nocheck
local test = require("@std/test")
local Node = require("./node")

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

local function hasParams(matches, expected)
	for _, match in matches do
		if match.params ~= nil then
			local ok = true
			for key, value in expected do
				if match.params[key] ~= value then
					ok = false
					break
				end
			end
			for key in match.params do
				if expected[key] == nil then
					ok = false
					break
				end
			end
			if ok then
				return true
			end
		end
	end
	return false
end

test.suite("node", function()
	test.case("stores multiple handlers for the same method and path in insertion order", function(asserts)
		local node = Node.new()
		node:insert("GET", "/same", handler("first"))
		node:insert("GET", "/same", handler("second"))

		local res = Node.search(node, "GET", { "same" }, 1)

		asserts.eq(values(res), { "first", "second" })
	end)

	test.case("returns method and ALL handlers from the terminal node", function(asserts)
		local node = Node.new()
		node:insert("ALL", "/same", handler("all"))
		node:insert("GET", "/same", handler("get"))

		local get = Node.search(node, "GET", { "same" }, 1)
		local post = Node.search(node, "POST", { "same" }, 1)

		asserts.eq(values(get), { "get", "all" })
		asserts.eq(values(post), { "all" })
	end)

	test.case("copies params while exploring multiple param branches", function(asserts)
		local node = Node.new()
		node:insert("GET", "/:resource/:id", handler("resource"))
		node:insert("GET", "/:resource/static", handler("static"))

		local res = Node.search(node, "GET", { "users", "static" }, 1)

		asserts.eq(#res, 2)
		asserts.that(hasParams(res, {
			resource = "users",
			id = "static",
		}))
		asserts.that(hasParams(res, {
			resource = "users",
		}))
	end)

	test.case("returns an empty handler list for an exact path with no matching method", function(asserts)
		local node = Node.new()
		node:insert("POST", "/submit", handler("post"))

		local res = Node.search(node, "GET", { "submit" }, 1)

		asserts.neq(res, nil)
		asserts.eq(#res, 0)
	end)

	test.case("returns nil when traversal cannot continue", function(asserts)
		local node = Node.new()
		node:insert("GET", "/known", handler("known"))

		local res = Node.search(node, "GET", { "missing" }, 1)

		asserts.eq(res, nil)
	end)
end)
