import Vapor



func routes(_ app: Application) throws {
	app.get("healthz", "live",  use: { req in (req.application.firstCloneSucceeded ?? true)  ? Response(body: "ok") : Response(status: .serviceUnavailable) })
	app.get("healthz", "ready", use: { req in (req.application.firstCloneSucceeded ?? false) ? Response(body: "ok") : Response(status: .serviceUnavailable) })
}
