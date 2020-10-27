import Foundation

import Metrics
import Prometheus
import Vapor



/* Configure the application */
public func configure(_ app: Application) throws {
	let configPath = Environment.get("HTTP_SERVER_FOR_GIT_REPOS__CONFIG_PATH") ?? "/etc/http-server-for-git-repos/config.json"
	
	let configReader = JSONDecoder()
	configReader.keyDecodingStrategy = .convertFromSnakeCase
	app.config = try configReader.decode(ServerConfig.self, from: Data(contentsOf: URL(fileURLWithPath: configPath)))
	
	/* Bootstrap prom for the metrics */
	MetricsSystem.bootstrap(PrometheusClient())
	
	app.repoUpdater = RepoUpdater()
	
	/* Register the routes */
	// app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
	try routes(app)
	
	/* Fills the app’s storage; see comment in function for details. */
	app.warmUpStorage(app)
	
	/* Config is done, we start the repos updater. */
	_ = app.repoUpdater.startScheduledUpdates(app)
		.always{ _ in
			app.firstCloneDone = true
		}
}
