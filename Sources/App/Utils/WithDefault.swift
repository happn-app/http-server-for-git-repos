/*
 * WithDefault.swift
 * fastlane-server
 *
 * Created by François Lamboley on 17/07/2020.
 */

import Foundation



public protocol DefaultProvider {
	
	associatedtype ValueType
	static var defaultValue: ValueType {get}
	
}

/* Swift only has generics. If it had templates like C++, I could’ve put the
 * default value in the template intead of doing a workaround via a protocol. */
@propertyWrapper
public struct WithDefault<ValueType, DefaultProviderType : DefaultProvider> {
	
	public init(_ defaultValueProvider: DefaultProviderType.Type) where DefaultProviderType.ValueType == ValueType {
		wrappedValue = defaultValueProvider.defaultValue
	}
	
	public var wrappedValue: ValueType
	
}

extension WithDefault : Decodable where ValueType : Decodable {
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		wrappedValue = try container.decode(ValueType.self)
	}
	
}

public extension KeyedDecodingContainer {
	func decode<T, P>(_ type: WithDefault<T, P>.Type, forKey key: Key) throws -> WithDefault<T, P> where T == P.ValueType, T : Decodable {
		try decodeIfPresent(type, forKey: key) ?? WithDefault<T, P>(P.self)
	}
}
