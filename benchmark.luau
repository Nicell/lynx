--!native
-- Implementation of this benchmark: https://hono.dev/docs/concepts/benchmarks

local process = require("@lute/process")
local Router = require("@lynx/router")

local includeInit = table.find(process.args, "--init") ~= nil

local noop = function()
	return nil
end

local function buildRouter()
	local router = Router.new()

	router:add("GET", "/user", noop)
	router:add("GET", "/user/comments", noop)
	router:add("GET", "/user/avatar", noop)
	router:add("GET", "/user/lookup/username/:username", noop)
	router:add("GET", "/user/lookup/email/:address", noop)
	router:add("GET", "/event/:id", noop)
	router:add("GET", "/event/:id/comments", noop)
	router:add("POST", "/event/:id/comment", noop)
	router:add("GET", "/map/:location/events", noop)
	router:add("GET", "/status", noop)
	router:add("GET", "/very/deeply/nested/route/hello/there", noop)
	router:add("GET", "/static/*", noop)

	return router
end

local router = buildRouter()

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

local ITERATIONS = if includeInit then 100000 else 1000000

for _, route in routes do
	local total = 0
	for _ = 1, ITERATIONS do
		local start = os.clock()
		if includeInit then
			Router.match(buildRouter(), route.method, route.path)
		else
			Router.match(router, route.method, route.path)
		end
		local finish = os.clock()
		total += finish - start
	end

	local average = total / ITERATIONS
	local averageNs = average * 1e9

	print(route.name, math.ceil(averageNs), "ns")
end

local totalTogether = 0

for _ = 1, ITERATIONS do
	if includeInit then
		local start = os.clock()
		local r = buildRouter()
		for _, route in routes do
			Router.match(r, route.method, route.path)
		end
		local finish = os.clock()
		totalTogether += finish - start
	else
		for _, route in routes do
			local start = os.clock()
			Router.match(router, route.method, route.path)
			local finish = os.clock()
			totalTogether += finish - start
		end
	end
end

local average = totalTogether / ITERATIONS
local averageNs = average * 1e9

print("all together", math.ceil(averageNs), "ns")
