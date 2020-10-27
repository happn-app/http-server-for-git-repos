/*
 * VaporServices.swift
 *
 *
 * Created by François Lamboley on 26/10/2020.
 */

import Foundation

import Vapor



extension Application {
	
	var config: ServerConfig {
		get {storage[ConfigKey.self]!}
		set {storage[ConfigKey.self] = newValue}
	}
	
	private struct ConfigKey: StorageKey {
		typealias Value = ServerConfig
	}
	
	var firstCloneDone: Bool {
		get {storage[FirstCloneSucceededKey.self] ?? false}
		set {storage[FirstCloneSucceededKey.self] = newValue}
	}
	
	private struct FirstCloneSucceededKey: StorageKey {
		typealias Value = Bool
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
