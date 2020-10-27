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
				self.q.asyncAfter(deadline: .now() + .milliseconds(Int(t * 1000)), execute: {
					_ = self.startScheduledUpdates(app)
				})
			}
	}
	
	func updateAllRepos(_ app: Application) -> EventLoopFuture<Void> {
		return EventLoopFuture.reduce((), app.config.repos.map{ repoCloner.cloneOrUpdateRepo($0, app: app) }, on: app.eventLoopGroup.next(), { _,_ in })
	}
	
	private let q = DispatchQueue(label: "com.happn.http-server-for-git-repos.RepoUpdaterQueue")
	private let repoCloner = RepoCloner()
	
}
