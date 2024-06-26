//
//  FeedlyLink.swift
//  Account
//
//  Created by Kiel Gillard on 3/10/19.
//  Copyright © 2019 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public struct FeedlyLink: Decodable, Sendable {

	public let href: String

	/// The mime type of the resource located by `href`.
	/// When `nil`, it's probably a web page?
	/// https://groups.google.com/forum/#!searchin/feedly-cloud/feed$20url%7Csort:date/feedly-cloud/Rx3dVd4aTFQ/Hf1ZfLJoCQAJ
	public let type: String?
}
