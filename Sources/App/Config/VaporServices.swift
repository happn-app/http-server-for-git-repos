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
	
}
