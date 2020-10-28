import Foundation

import Metrics
import Vapor



func routes(_ app: Application) throws {
	app.middleware.use(FileMiddleware(publicDirectory: app.config.baseReposFolderURL.absoluteURL.path))
	
	app.get("_healthz", "live",  use: { _   in "ok" })
	app.get("_healthz", "ready", use: { req in req.application.firstCloneDone ? Response(body: "ok") : Response(status: .serviceUnavailable) })
	
	app.get("_metrics", use: { req -> EventLoopFuture<String> in
		let promise = req.eventLoop.makePromise(of: String.self)
		try MetricsSystem.prometheus().collect(into: promise)
		return promise.futureResult
	})
	
	app.post("_update-repos", use: { req -> String in
		_ = req.application.repoUpdater.updateAllRepos(req.application)
		return "ok"
	})
}
