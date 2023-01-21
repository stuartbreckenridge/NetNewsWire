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
	public let `description`: String
}

