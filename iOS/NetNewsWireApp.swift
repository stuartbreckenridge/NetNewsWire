//
//  NetNewsWireApp.swift
//  NetNewsWire
//
//  Created by Stuart Breckenridge on 17/06/2026.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import SwiftUI

@main
struct NetNewsWireApp: App {

	var body: some Scene {
		WindowGroup {
			NavigationSplitView {
				MainFeedListView()
			} content: {
				ContentUnavailableView("Timeline", systemImage: "calendar.day.timeline.leading")
			} detail: {
				ContentUnavailableView("Article", systemImage: "newspaper")
			}
			.navigationSplitViewStyle(.prominentDetail)
			.toolbar {
				ToolbarItemGroup(placement: .bottomBar, content: {})
			}
		}
	}
}
