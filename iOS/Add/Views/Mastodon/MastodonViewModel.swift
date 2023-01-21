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
	@Published public var userNameOrHashtag: String = ""
	@Published public var server: String = ""
	@Published public var optionalTitle: String = ""
	@Published public var showServerSuggestions: Bool = false
	@Published public var selectedFolder: String = ""
	@Published public var showFeedFolderSelector: Bool = false
	
	// Private
	private var allServers: [MastodonServer] = []
	private let serverUrl = URL(string: "https://api.joinmastodon.org/servers")!
	
	// MARK: - Public API
	
	public func refreshServerList() async {
		do {
			allServers = try await MastodonAPI.shared.refreshServerList() ?? []
		} catch {
			apiError = (true, error)
		}
	}
	
	public func searchFor(_ server: String) {
		filteredServers = allServers.filter({ $0.domain.localizedCaseInsensitiveContains(server) })
	}
	
	public func followUser(_ username: String, server: String, title: String?) async throws {
		showProgressIndicator = true
		let urlString = "https://\(server)/users/\(username).rss"
		let container = containers[selectedFolderIndex]
		
		if let account = container.account {
			if account.hasWebFeed(withURL: urlString) {
				showProgressIndicator = false
				throw AccountError.createErrorAlreadySubscribed
			}
			
			try await withCheckedThrowingContinuation { continuation in
				account.createWebFeed(url: urlString, name: title, container: container, validateFeed: true, completion: { [weak self] result in
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
	
	public func followTag(_ tag: String, server: String, title: String?) async throws {
		showProgressIndicator = true
		let urlString = "https://\(server)/tags/\(tag).rss"
		let container = containers[selectedFolderIndex]
		
		if let account = container.account {
			if account.hasWebFeed(withURL: urlString) {
				showProgressIndicator = false
				throw AccountError.createErrorAlreadySubscribed
			}
			
			try await withCheckedThrowingContinuation { continuation in
				account.createWebFeed(url: urlString, name: title, container: container, validateFeed: true, completion: { [weak self] result in
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
}
