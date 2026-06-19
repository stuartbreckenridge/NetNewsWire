//
//  ApplicationCoordinator.swift
//  NetNewsWire-iOS
//
//  Created by Stuart Breckenridge on 19/06/2026.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import Foundation
import os
import UserNotifications
import Account
import Articles
import RSCore
import RSTree
import SafariServices
import SwiftUI
import Images

@Observable
@MainActor
final class ApplicationCoordinator {

	// MARK: Navigation State
	var filterRead: Bool = false
	var showAddFeed: Bool = false
	var showAddFolder: Bool = false
	var showCurrentActivity: Bool = false
	var showSettings: Bool = false

	// MARK: Activities
	private var activityManager = ActivityManager()

	// MARK: Fetching
	private let fetchAndMergeArticlesQueue = CoalescingQueue(name: "Fetch and Merge Articles", interval: 0.5)
	private let rebuildBackingStoresQueue = CoalescingQueue(name: "Rebuild The Backing Stores", interval: 0.5)
	private var fetchSerialNumber = 0
	private let fetchRequestQueue = FetchRequestQueue()

	// MARK: Logging
	private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ApplicationCoordinator")

	static let shared = ApplicationCoordinator()

	private init() {
		ApplicationCoordinator.logger.debug("ApplicationCoordinator initialised")
	}

}
