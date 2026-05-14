--!nocheck
local test = require("@std/test")
local Lynx = require("./lynx")

local function request(path: string, method: string?)
	return {
		method = method or "GET",
		path = path,
		body = "",
		headers = {},
		query = {},
	}
end

test.suite("lynx", function()
	test.case("dispatches middleware and handlers in definition order", function(asserts)
		local app = Lynx.new()
		local calls = {}

		app:use(function(c, next)
			table.insert(calls, "middleware before")
			c:header("X-Before", "yes")
			next()
			table.insert(calls, "middleware after")
			c:header("X-After", "yes")
		end)

		app:get("/ok", function(c)
			table.insert(calls, "handler")
			return c:text("ok")
		end)

		local res = app:request("/ok")

		asserts.eq(res.status, 200)
		asserts.eq(res.body, "ok")
		asserts.eq(res.headers["Content-Type"], "text/plain; charset=utf-8")
		asserts.eq(res.headers["X-Before"], "yes")
		asserts.eq(res.headers["X-After"], "yes")
		asserts.eq(calls, { "middleware before", "handler", "middleware after" })
	end)

	test.case("uses first registered matching route even when a later route is more specific", function(asserts)
		local app = Lynx.new()
		app:get("/*", function(c)
			return c:text("wildcard")
		end)
		app:get("/two", function(c)
			return c:text("exact")
		end)

		local res = app:request("/two")

		asserts.eq(res.body, "wildcard")
	end)

	test.case("passes params from mounted sub-app routes", function(asserts)
		local app = Lynx.new()
		local api = Lynx.new()

		api:get("/users/:id", function(c)
			return c:text(c.req.params.id)
		end)

		app:route("/api", api)

		local res = app:request("/api/users/42")

		asserts.eq(res.status, 200)
		asserts.eq(res.body, "42")
	end)

	test.case("runs path-scoped middleware only for matching paths", function(asserts)
		local app = Lynx.new()
		local adminMiddlewareCalls = 0

		app:use("/admin/*", function(c, next)
			adminMiddlewareCalls += 1
			if not c.req.headers.authorization then
				return c:status(401):text("Unauthorized")
			end
			return next()
		end)

		app:get("/admin/dashboard", function(c)
			return c:text("admin")
		end)

		app:get("/public", function(c)
			return c:text("public")
		end)

		local unauthorized = app:request("/admin/dashboard")
		local public = app:request("/public")
		local authorized = app:request({
			method = "GET",
			path = "/admin/dashboard",
			body = "",
			headers = {
				authorization = "Bearer token",
			},
			query = {},
		})

		asserts.eq(unauthorized.status, 401)
		asserts.eq(unauthorized.body, "Unauthorized")
		asserts.eq(public.status, 200)
		asserts.eq(public.body, "public")
		asserts.eq(authorized.status, 200)
		asserts.eq(authorized.body, "admin")
		asserts.eq(adminMiddlewareCalls, 2)
	end)

	test.case("uses custom not found and error handlers", function(asserts)
		local app = Lynx.new()

		app:notFound(function(c)
			return c:text(`missing {c.req.method} {c.req.path}`, 404)
		end)

		app:onError(function(c, err)
			return c:text(`error: {err}`, 500)
		end)

		app:get("/boom", function(_c)
			error("boom")
		end)

		local missing = app:request("/missing")
		local errorResponse = app:request("/boom")

		asserts.eq(missing.status, 404)
		asserts.eq(missing.body, "missing GET /missing")
		asserts.eq(errorResponse.status, 500)
		asserts.strContains(errorResponse.body :: string, "error: ")
		asserts.strContains(errorResponse.body :: string, "boom")
	end)

	test.case("supports non-GET request tables", function(asserts)
		local app = Lynx.new()

		app:post("/submit", function(c)
			return c:text(c.req.method)
		end)

		local res = app:request(request("/submit", "POST"))

		asserts.eq(res.status, 200)
		asserts.eq(res.body, "POST")
	end)
end)
