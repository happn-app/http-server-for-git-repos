import Vapor



/* Configure the application */
public func configure(_ app: Application) throws {
	// uncomment to serve files from /Public folder
	// app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
	
	/* Register the routes */
	try routes(app)
}
