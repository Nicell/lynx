-- Implementation of this benchmark: https://hono.dev/docs/concepts/benchmarks

local Router = require("src/router")

local router = Router.new()

router:add("GET", "/user", function() end)
router:add("GET", "/user/comments", function() end)
router:add("GET", "/user/avatar", function() end)
router:add("GET", "/user/lookup/username/:username", function() end)
router:add("GET", "/user/lookup/email/:address", function() end)
router:add("GET", "/event/:id", function() end)
router:add("GET", "/event/:id/comments", function() end)
router:add("POST", "/event/:id/comment", function() end)
router:add("GET", "/map/:location/events", function() end)
router:add("GET", "/status", function() end)
router:add("GET", "/very/deeply/nested/route/hello/there", function() end)
router:add("GET", "/static/*", function() end)

local routes = {
	{
		name = "short static",
		method = "GET",
		path = "/user",
	},
	{
		name = "static with same radix",
		method = "GET",
		path = "/user/comments",
	},
	{
		name = "dynamic route",
		method = "GET",
		path = "/user/lookup/username/hey",
	},
	{
		name = "mixed static dynamic",
		method = "GET",
		path = "/event/abcd1234/comments",
	},
	{
		name = "post",
		method = "POST",
		path = "/event/abcd1234/comment",
	},
	{
		name = "long static",
		method = "GET",
		path = "/very/deeply/nested/route/hello/there",
	},
	{
		name = "wildcard",
		method = "GET",
		path = "/static/index.html",
	},
}

local ITERATIONS = 100000

for _, route in routes do
	local total = 0
	for _ = 1, ITERATIONS do
		local start = os.clock()
		router:match(route.method, route.path)
		local finish = os.clock()
		total += finish - start
	end

	local average = total / ITERATIONS
	local averageNs = average * 1e9

	print(route.name, math.ceil(averageNs), "ns")
end

local totalTogether = 0

for _ = 1, ITERATIONS do
	local start = os.clock()
	for _, route in routes do
		router:match(route.method, route.path)
	end
	local finish = os.clock()
	totalTogether += finish - start
end

local average = totalTogether / ITERATIONS
local averageNs = average * 1e9

print("all together", math.ceil(averageNs), "ns")
