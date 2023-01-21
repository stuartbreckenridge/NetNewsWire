//
//  MastodonAPI.swift
//  NetNewsWire
//
//  Created by Stuart Breckenridge on 21/01/2023.
//  Copyright © 2023 Ranchero Software. All rights reserved.
//

import Foundation
import RSCore


public final class MastodonAPI: Logging {
	
	public static let shared = MastodonAPI()
	
	private let serverUrl = URL(string: "https://api.joinmastodon.org/servers")!
	
	public func refreshServerList() async throws -> [MastodonServer]? {
		if let servers = await cachedServerList() {
			return servers
		} else {
			let request = URLRequest(url: serverUrl)
			do {
				self.logger.debug("Retrieving Mastodon servers.")
				let (data, _) = try await URLSession.shared.data(for: request)
				var decodedServers = try JSONDecoder().decode([MastodonServer].self, from: data)
				if decodedServers.contains(where: { $0.domain == "mastodon.social" }) == false {
					decodedServers.append(MastodonServer(domain: "mastodon.social", description: "The original server operated by the Mastodon gGmbH non-profit."))
				}
				return decodedServers.sorted(by: { $0.domain < $1.domain })
			} catch {
				logger.error("\(error.localizedDescription)")
				throw error
			}
		}
	}
	
	private func cachedServerList() async -> [MastodonServer]? {
		await withCheckedContinuation { continuation in
			let request = URLRequest(url: serverUrl)
			let task = URLSession.shared.dataTask(with: request)
			
			URLCache.shared.getCachedResponse(for: task) { response in
				if let data = response?.data {
					if var decodedServers = try? JSONDecoder().decode([MastodonServer].self, from: data) {
						self.logger.debug("Returning Mastodon servers from cache.")
						if decodedServers.contains(where: { $0.domain == "mastodon.social" }) == false {
							decodedServers.append(MastodonServer(domain: "mastodon.social", description: "The original server operated by the Mastodon gGmbH non-profit."))
						}
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
