//
//  AppNotifications.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 8/30/15.
//  Copyright © 2015 Ranchero Software, LLC. All rights reserved.
//

import Foundation


extension Notification.Name {
	static let InspectableObjectsDidChange = Notification.Name("TimelineSelectionDidChangeNotification")
	static let UserDidAddFeed = Notification.Name("UserDidAddFeedNotification")

	#if !MAC_APP_STORE
		static let WebInspectorEnabledDidChange = Notification.Name("WebInspectorEnabledDidChange")
	#endif
}
