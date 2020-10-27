/*
 * RepoUpdater.swift
 *
 *
 * Created by François Lamboley on 27/10/2020.
 */

import Foundation

import NIO
import Vapor



final class RepoUpdater {
	
	/** Clones or updates all repos, returns a future for the first clone, then
	updates the repos at given time interval in config. */
	func startScheduledUpdates(_ app: Application) -> EventLoopFuture<Void> {
		return updateAllRepos(app)
			.always{ _ in
				guard let t = app.config.pullInterval else {
					return
				}
				self.timeQ.asyncAfter(deadline: .now() + .milliseconds(Int(t * 1000)), execute: {
					_ = self.startScheduledUpdates(app)
				})
			}
	}
	
	func updateAllRepos(_ app: Application) -> EventLoopFuture<Void> {
		let eventLoop = app.eventLoopGroup.next()
		return EventLoopFuture.reduce((), app.config.repos.map{ updateRepo($0, app: app, eventLoop: eventLoop) }, on: eventLoop, { _,_ in })
	}
	
	func updateRepo(_ repo: ServerConfig.Repo, app: Application, req: Request? = nil, eventLoop: EventLoop) -> EventLoopFuture<Void> {
		return syncQ.sync{
			let localRepoURL = app.config.localURL(for: repo)
			let r: EventLoopFuture<Void>
			if let f = futureUpdateByRepoURL[localRepoURL] {
				r = f.hop(to: eventLoop).flatMapAlways{ _ in
					return self.repoCloner.cloneOrUpdateRepo(repo, app: app, req: req).hop(to: eventLoop)
				}
			} else {
				r = repoCloner.cloneOrUpdateRepo(repo, app: app, req: req).hop(to: eventLoop)
			}
			futureUpdateByRepoURL[localRepoURL] = r
			_ = r.always{ _ in
				self.syncQ.sync{
					if self.futureUpdateByRepoURL[localRepoURL] === r {
						self.futureUpdateByRepoURL.removeValue(forKey: localRepoURL)
					}
				}
			}
			return r
		}
	}
	
	private let syncQ = DispatchQueue(label: "com.happn.http-server-for-git-repos.RepoUpdaterQueueForSync")
	private let timeQ = DispatchQueue(label: "com.happn.http-server-for-git-repos.RepoUpdaterQueueForTime")
	private let repoCloner = RepoCloner()
	
	private var futureUpdateByRepoURL = [URL: EventLoopFuture<Void>]()
	
}
