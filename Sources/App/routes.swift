import Vapor



func routes(_ app: Application) throws {
	app.get("_healthz", "live",  use: { _   in "ok" })
	app.get("_healthz", "ready", use: { req in req.application.firstCloneDone ? Response(body: "ok") : Response(status: .serviceUnavailable) })
}
