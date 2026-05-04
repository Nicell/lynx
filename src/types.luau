local Runtime = require("./runtime")
local Context = require("./context")

type Context = Context.Context
export type Handler = (c: Context) -> Runtime.ServeResponse
export type ErrorHandler = (c: Context, error: string) -> Runtime.ServeResponse
export type Middleware = (c: Context, next: () -> ()) -> Runtime.ServeResponse?
export type MatchResponse = { { params: { [string]: string }?, handler: Handler | Middleware, score: number } }

return {}
