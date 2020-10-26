/*
 * SimpleError.swift
 *
 *
 * Created by François Lamboley on 26/10/2020.
 */

import Foundation



public struct SimpleError : Error {
	
	public var message: String
	
	public init(message: String) {
		self.message = message
	}
	
}
