/*
 * VaporServices.swift
 *
 *
 * Created by François Lamboley on 26/10/2020.
 */

import Foundation

import Vapor



extension Application {
	
	func warmUpStorage(_ app: Application) {
		/* This whole function should be removed once storage is thread-safe (see
		 * https://github.com/vapor/vapor/issues/2330).
		 * In the mean time we force get all the properties that set something in
		 * the storage so the storage is effectively read-only later.
		 * Must be done after the app is configured. */
		_ = app.config /* This one is technically not needed… */
		_ = app.firstCloneDone
		_ = app.repoUpdater
		_ = app.gitQueue
	}
	
}

extension Application {
	
	var config: ServerConfig {
		get {storage[ConfigKey.self]!}
		set {storage[ConfigKey.self] = newValue}
	}
	
	private struct ConfigKey: StorageKey {
		typealias Value = ServerConfig
	}
	
	var firstCloneDone: Bool {
		get {
			locks.lock(for: FirstCloneDoneLock.self).withLock{
				if let existing = storage[FirstCloneDoneKey.self] {
					return existing.value
				} else {
					storage[FirstCloneDoneKey.self] = Ref(false)
					return false
				}
			}
		}
		set {
			locks.lock(for: FirstCloneDoneLock.self).withLock{
				storage[FirstCloneDoneKey.self]!.value = newValue
			}
		}
	}
	
	private struct FirstCloneDoneKey: StorageKey {
		typealias Value = Ref<Bool>
	}
	private struct FirstCloneDoneLock : LockKey {}
	
	var repoUpdater: RepoUpdater {
		get {storage[RepoUpdaterKey.self]!}
		set {storage[RepoUpdaterKey.self] = newValue}
	}
	
	private struct RepoUpdaterKey: StorageKey {
		typealias Value = RepoUpdater
	}
	
	var gitQueue: DispatchQueue {
		if let existing = storage[GitQueueKey.self] {
			return existing
		} else {
			let new = DispatchQueue(label: "com.happn.http-server-for-git-repos.gitq", qos: .background, attributes: .concurrent)
			storage[GitQueueKey.self] = new
			return new
		}
	}
	
	private struct GitQueueKey: StorageKey {
		typealias Value = DispatchQueue
	}
	
}
