//
//  FeedWranglerConfig.swift
//  NetNewsWire
//
//  Created by Jonathan Bennett on 9/27/19.
//  Copyright © 2019 Ranchero Software, LLC. All rights reserved.
//

import Foundation


enum FeedWranglerConfig {
	static let pageSize = 100
    static let idsPageSize = 1000
	static let clientPath = "https://feedwrangler.net/api/v2/"
	static let clientURL = {
		URL(string: FeedWranglerConfig.clientPath)!
	}()
}
