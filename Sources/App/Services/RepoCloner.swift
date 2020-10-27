/*
 * RepoCloner.swift
 *
 *
 * Created by François Lamboley on 27/10/2020.
 */

import Foundation

import NIO
import Metrics
import Vapor
import SwiftShell



final class RepoCloner {
	
	func cloneOrUpdateRepo(_ repo: ServerConfig.Repo, app: Application, req: Request? = nil) -> EventLoopFuture<Void> {
		let config = app.config
		let logger = req?.logger ?? app.logger
		let eventLoop = req?.eventLoop ?? app.eventLoopGroup.next()
		
		let localRepoPath = config.localURL(for: repo).path
		logger.info("Cloning or updating \(repo.url) in \(localRepoPath)")
		
		let startTime = DispatchTime.now()
		let promise = eventLoop.makePromise(of: Void.self)
		do {
			var context = CustomContext()
			context.env["PATH"] = main.env["PATH"]
			context.currentdirectory = main.currentdirectory
			if let credName = repo.credentialName {
				guard let creds = config.credentials[credName] else {
					throw SimpleError(message: "Invalid config for repo “\(repo.url)”: credential name “\(credName)” does not exist.")
				}
				switch creds {
					case .sshKey(let path):
						let allowedChars = CharacterSet(charactersIn: "-_.+=/abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
						guard path.rangeOfCharacter(from: allowedChars.inverted) == nil else {
							throw SimpleError(message: "Invalid config for cred “\(credName)”: The path to the SSH key contains an invalid char.")
						}
						context.env["GIT_SSH_COMMAND"] = "ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i '\(path)' -F /dev/null"
				}
			}
			
			if FileManager.default.fileExists(atPath: localRepoPath) && FileManager.default.enumerator(atPath: localRepoPath)?.nextObject() != nil {
				/* A file or folder already exists at repo local path. We assume it
				 * is a previous clone of the repo and we just fetch. */
				app.gitQueue.async{
					let err = (
						self.runAndLogStderr(context: context, logger: logger, "/usr/bin/env", "git", "-C", localRepoPath, "remote", "set-url", "origin", repo.url).error ??
						self.runAndLogStderr(context: context, logger: logger, "/usr/bin/env", "git", "-C", localRepoPath, "fetch", "-pf", "origin").error ??
						self.updateLocalRepoBranch(localRepoPath, gitRef: repo.gitRef, context: context, logger: logger)
					)
					self.endPromiseAndLog(repoURL: repo.url, promise: promise, error: err, startTime: startTime, logger: logger)
				}
			} else {
				/* No file or folder at repo local path. We must clone the repo. */
				app.gitQueue.async{
					let err = (
						self.runAndLogStderr(context: context, logger: logger, "/usr/bin/env", "git", "clone", "--origin", "origin", repo.url, localRepoPath).error ??
						self.updateLocalRepoBranch(localRepoPath, gitRef: repo.gitRef, context: context, logger: logger)
					)
					self.endPromiseAndLog(repoURL: repo.url, promise: promise, error: err, startTime: startTime, logger: logger)
				}
			}
		} catch {
			endPromiseAndLog(repoURL: repo.url, promise: promise, error: error, startTime: startTime, logger: logger)
		}
		return promise.futureResult
	}
	
	private func updateLocalRepoBranch(_ repoPath: String, gitRef: String, context: CommandRunning, logger: Logger) -> Error? {
		let resCheckout = runAndLogStderr(context: context, logger: logger, "/usr/bin/env", "git", "-C", repoPath, "checkout", "http-server-for-git-repos")
		if !resCheckout.succeeded {
			let resCheckoutCreate = runAndLogStderr(context: context, logger: logger, "/usr/bin/env", "git", "-C", repoPath, "checkout", "-b", "http-server-for-git-repos")
			if let err = resCheckoutCreate.error {return err}
		}
		
		let resReset = runAndLogStderr(context: context, logger: logger, "/usr/bin/env", "git", "-C", repoPath, "reset", "--hard", gitRef)
		if let err = resReset.error {return err}
		
		return nil
	}
	
	private func runAndLogStderr(context: CommandRunning, logger: Logger, _ executableName: String, _ arguments: Any...) -> RunOutput {
		let res = context.run(executableName, arguments)
		if !res.stderror.isEmpty {
			logger.debug("Command '\(executableName) \(arguments.map(String.init(describing:)).joined(separator: " "))' got stderr: \(res.stderror)")
		}
		return res
	}
	
	private func endPromiseAndLog(repoURL: URL, promise: EventLoopPromise<Void>, error: Error?, startTime: DispatchTime, logger: Logger) {
		let dimensions = [("repo_url", repoURL.absoluteString)]
		Timer(
			label: "repo_clone_duration_seconds",
			dimensions: dimensions,
			preferredDisplayUnit: .seconds
		).recordNanoseconds(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds)
		
		Counter(label: "repo_clone_total", dimensions: dimensions).increment()
		
		if let error = error {
			Counter(label: "repo_clone_errors_total", dimensions: dimensions).increment()
			logger.error("Error while updating repo “\(repoURL)”: \(error)")
			promise.fail(error)
		} else {
			promise.succeed(())
		}
	}
	
}
