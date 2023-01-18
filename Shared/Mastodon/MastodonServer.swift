//
//  MastodonServer.swift
//  NetNewsWire
//
//  Created by Stuart Breckenridge on 17/01/2023.
//  Copyright © 2023 Ranchero Software. All rights reserved.
//

import Foundation

public struct MastodonServer: Codable, Identifiable {
	public var id: String { domain }
	public let domain: String
	public let version: String
	public let `description`: String
	public let languages: [String]
	public let region: String
	public let categories: [String]
	public let proxied_thumbnail: String
	public let blurhash: String?
	public let total_users: Int
	public let last_week_users: Int
	public let approval_required: Bool
	public let language: String
	public let category: String
}

