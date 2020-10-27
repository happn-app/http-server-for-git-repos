import Vapor



/* Configure the application */
public func configure(_ app: Application) throws {
	let configPath = Environment.get("HTTP_SERVER_FOR_GIT_REPOS__CONFIG_PATH") ?? "/etc/http-server-for-git-repos/config.json"
	
	let configReader = JSONDecoder()
	configReader.keyDecodingStrategy = .convertFromSnakeCase
	app.config = try configReader.decode(ServerConfig.self, from: Data(contentsOf: URL(fileURLWithPath: configPath)))
	
	/* Register the routes */
	// app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
	try routes(app)
	
	/* Fills the app’s storage; see comment in function for details. */
	warmUpStorage(app)
	
	/* Config is done, we start the repos updater. */
	/* TODO: For now we only clone once. */
	let repoCloner = RepoCloner()
	_ = EventLoopFuture.reduce((), app.config.repos.map{ repoCloner.cloneOrUpdateRepo($0, app: app) }, on: app.eventLoopGroup.next(), { _,_ in })
		.always{ result in
			switch result {
				case .success: app.firstCloneSucceeded = true
				case .failure: app.firstCloneSucceeded = false
			}
		}
}


private func warmUpStorage(_ app: Application) {
	/* This whole function should be removed once storage is thread-safe (see
	 * https://github.com/vapor/vapor/issues/2330).
	 * In the mean time we force get all the properties that set something in the
	 * storage so the storage is effectively read-only later.
	 * Must be done after the app is configured. */
	_ = app.config /* This one is technically not needed… */
	_ = app.gitQueue
}
