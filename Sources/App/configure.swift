import Vapor



/* Configure the application */
public func configure(_ app: Application) throws {
	// uncomment to serve files from /Public folder
	// app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
	let configPath = Environment.get("HTTP_SERVER_FOR_GIT_REPOS__CONFIG_PATH") ?? "/etc/http-server-for-git-repos/config.json"
	
	let configReader = JSONDecoder()
	configReader.keyDecodingStrategy = .convertFromSnakeCase
	let config = try configReader.decode(ServerConfig.self, from: Data(contentsOf: URL(fileURLWithPath: configPath)))
	print(config)
	
	/* Register the routes */
	try routes(app)
}
