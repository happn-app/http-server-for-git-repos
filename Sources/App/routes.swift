import Vapor



func routes(_ app: Application) throws {
	app.get("healthz", "live", use: { _ in "ok" })
	app.get("healthz", "ready", use: { _ in return Response(status: .serviceUnavailable) })
}
