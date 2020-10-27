import Vapor



/* Configure the application */
public func configure(_ app: Application) throws {
	let configPath = Environment.get("HTTP_SERVER_FOR_GIT_REPOS__CONFIG_PATH") ?? "/etc/http-server-for-git-repos/config.json"
	
	let configReader = JSONDecoder()
	configReader.keyDecodingStrategy = .convertFromSnakeCase
	app.config = try configReader.decode(ServerConfig.self, from: Data(contentsOf: URL(fileURLWithPath: configPath)))
	
	app.repoUpdater = RepoUpdater()
	
	/* Register the routes */
	// app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
	try routes(app)
	
	/* Fills the app’s storage; see comment in function for details. */
	app.warmUpStorage(app)
	
	/* Config is done, we start the repos updater. */
	/* TODO: For now we only clone once. */
	let repoCloner = RepoCloner()
	_ = EventLoopFuture.reduce((), app.config.repos.map{ repoCloner.cloneOrUpdateRepo($0, app: app) }, on: app.eventLoopGroup.next(), { _,_ in })
		.always{ _ in
			app.firstCloneDone = true
		}
}
