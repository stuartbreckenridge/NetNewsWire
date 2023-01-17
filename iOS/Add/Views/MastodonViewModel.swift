//
//  MastodonViewModel.swift
//  NetNewsWire
//
//  Created by Stuart Breckenridge on 17/01/2023.
//  Copyright © 2023 Ranchero Software. All rights reserved.
//

import Foundation
import Account
import RSCore

@MainActor
public final class MastodonViewModel: FeedFolderResolver, Logging  {
	
	// Published
	@Published public var filteredServers: [MastodonServer] = []
	@Published public var apiError: (Bool, Error?) = (false, nil)
	@Published public var showProgressIndicator: Bool = false
	
	// Private
	private var allServers: [MastodonServer] = []
	private let serverUrl = URL(string: "https://api.joinmastodon.org/servers")!
	
	// MARK: - Public API
	
	public func refreshServerList() async {
		if let servers = await cachedServerList() {
			allServers = servers
		} else {
			let request = URLRequest(url: serverUrl)
			do {
				self.logger.debug("Retrieving Mastodon servers.")
				let (data, _) = try await URLSession.shared.data(for: request)
				let decodedServers = try JSONDecoder().decode([MastodonServer].self, from: data)
				allServers = decodedServers.sorted(by: { $0.domain < $1.domain })
			} catch {
				apiError = (true, error)
			}
		}
	}
	
	public func searchFor(_ server: String) {
		filteredServers = allServers.filter({ $0.domain.localizedCaseInsensitiveContains(server) })
	}
	
	public func followUser(_ username: String, server: String) async throws {
		showProgressIndicator = true
		let urlString = "https://\(server)/users/\(username).rss"
		let container = containers[selectedFolderIndex]
		
		if let account = container.account {
			if account.hasWebFeed(withURL: urlString) {
				showProgressIndicator = false
				throw AccountError.createErrorAlreadySubscribed
			}
			
			try await withCheckedThrowingContinuation { continuation in
				account.createWebFeed(url: urlString, name: nil, container: container, validateFeed: true, completion: { [weak self] result in
					self?.showProgressIndicator = false
					switch result {
					case .success(let feed):
						NotificationCenter.default.post(name: .UserDidAddFeed, object: self, userInfo: [UserInfoKey.webFeed: feed])
						continuation.resume()
					case .failure(let error):
						continuation.resume(throwing: error)
					}
				})
			}
		}
		
	}
	
	public func followTag(_ tag: String, server: String) async throws {
		showProgressIndicator = true
		let urlString = "https://\(server)/tags/\(tag).rss"
		let container = containers[selectedFolderIndex]
		
		if let account = container.account {
			if account.hasWebFeed(withURL: urlString) {
				showProgressIndicator = false
				throw AccountError.createErrorAlreadySubscribed
			}
			
			try await withCheckedThrowingContinuation { continuation in
				account.createWebFeed(url: urlString, name: nil, container: container, validateFeed: true, completion: { [weak self] result in
					self?.showProgressIndicator = false
					switch result {
					case .success(let feed):
						NotificationCenter.default.post(name: .UserDidAddFeed, object: self, userInfo: [UserInfoKey.webFeed: feed])
						continuation.resume()
					case .failure(let error):
						continuation.resume(throwing: error)
					}
				})
			}
		}
		
	}
	
	
	
	// MARK: - Private API
	
	private func cachedServerList() async -> [MastodonServer]? {
		await withCheckedContinuation { continuation in
			let request = URLRequest(url: serverUrl)
			let task = URLSession.shared.dataTask(with: request)
			
			URLCache.shared.getCachedResponse(for: task) { response in
				if let data = response?.data {
					if let decodedServers = try? JSONDecoder().decode([MastodonServer].self, from: data) {
						self.logger.debug("Returning Mastodon servers from cache.")
						return continuation.resume(returning: decodedServers.sorted(by: { $0.domain < $1.domain }))
					} else {
						return continuation.resume(returning: nil)
					}
				} else {
					return continuation.resume(returning: nil)
				}
			}
		}
	}
	
}
