local net = require("@lune/net")
local Context = require("./context")

type Context = Context.Context
export type Handler = (c: Context) -> net.ServeResponse
export type ErrorHandler = (c: Context, error: string) -> net.ServeResponse
export type Middleware = (c: Context, next: () -> ()) -> net.ServeResponse?
export type MatchResponse = { { params: { [string]: string }?, handler: Handler | Middleware, score: number } }

return {}
