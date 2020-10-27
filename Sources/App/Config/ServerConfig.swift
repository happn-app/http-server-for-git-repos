/*
 * ServerConfig.swift
 *
 *
 * Created by François Lamboley on 23/10/2020.
 */

import Foundation



public struct ServerConfig : Decodable {
	
	public struct Repo : Codable {
		
		public var url: URL
		public var gitRef: String
		public var credentialName: String?
		
		public var endpointPath: String?
		
		public var relativeLocalPath: String?
		
	}
	
	public enum Credential : Decodable {
		
		/** Note: Only path containing alpha-num chars, and characters from
		`"=/-_.+"` are allowed. */
		case sshKey(_ path: String)
		/* Other cases later if needed. */
		
		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: Self.CodingKeys.self)
			
			let type = try container.decode(String.self, forKey: .type)
			switch type {
				case "ssh_key":
					self = try .sshKey(container.decode(String.self, forKey: .sshKeyPath))
					
				default:
					throw SimpleError(message: "Unknown type “\(type)” for credential")
			}
		}
		
		private enum CodingKeys : String, CodingKey {
			
			case type
			case sshKeyPath
			
		}
		
	}
	
	private struct DefaultRepos : DefaultProvider {static let defaultValue = [Repo]()}
	@WithDefault(DefaultRepos.self)
	public var repos: [Repo]
	
	private struct DefaultCredentials : DefaultProvider {static let defaultValue = [String: Credential]()}
	@WithDefault(DefaultCredentials.self)
	public var credentials: [String: Credential]
	
	public var webhookEndpoint: String?
	
	private struct DefaultPullInterval : DefaultProvider {static let defaultValue: TimeInterval? = 5*60}
	@WithDefault(DefaultPullInterval.self)
	public var pullInterval: TimeInterval?
	
	private struct DefaultBaseRepsFolderPath : DefaultProvider {static let defaultValue = FileManager.default.temporaryDirectory.path}
	/** The path to the folder in which the repositories will be cloned. */
	@WithDefault(DefaultBaseRepsFolderPath.self)
	public var baseReposFolderPath: String
	
	public var baseReposFolderURL: URL {
		URL(fileURLWithPath: baseReposFolderPath, isDirectory: true)
	}
	
	public func localURL(for repo: Repo) -> URL {
		return URL(fileURLWithPath: repo.relativeLocalPath ?? repo.url.deletingPathExtension().lastPathComponent, relativeTo: baseReposFolderURL)
	}
	
	public func endpointPath(for repo: Repo) -> String {
		return repo.endpointPath ?? "/" + repo.url.deletingPathExtension().lastPathComponent
	}
	
}
