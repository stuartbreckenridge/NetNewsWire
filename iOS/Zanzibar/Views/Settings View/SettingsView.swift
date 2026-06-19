//
//  SettingsView.swift
//  NetNewsWire-iOS
//
//  Created by Stuart Breckenridge on 19/06/2026.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import SwiftUI

struct SettingsView: View {

	// MARK: Environment
	@Environment(\.dismiss) private var dismiss

	// MARK: App Storage

	// MARK: State Objects

	// MARK: State

	// MARK: Bindings

	// MARK: Constants

	// MARK: Variables

    var body: some View {
		NavigationStack {
			List {
				Section {
					Button {
						UIApplication.shared.open(URL(string: "\(UIApplication.openSettingsURLString)")!)
					} label: {
						Text("label.text.open-system-settings", comment: "Open System Settings")
					}
					.foregroundStyle(.primary)

				} header: {
					Text("label.text.all-app-settings-header", comment: "Notifications, Badge, Data, & More")
				}

				Section {
					//
				} header: {
					Text("label.text.accounts", comment: "Accounts")
				}

				Section {
					//
				} header: {
					Text("label.text.feeds", comment: "Feeds")
				}

				Section {
					//
				} header: {
					Text("label.text.timeline", comment: "Timeline")
				}

				Section {
					//
				} header: {
					Text("label.text.articles", comment: "Articles")
				}

				Section {
					//
				} header: {
					Text("label.text.appearance", comment: "Appearance")
				}

				Section {
					//
				} header: {
					Text("label.text.troubleshooting", comment: "Troubleshooting")
				}

				Section {
					//
				} header: {
					Text("label.text.help", comment: "Help")
				} footer: {
					Text("label.text.app-name-\(Bundle.main.appName)-app-version-\(Bundle.main.versionNumber)-app-build-\(Bundle.main.buildNumber)", comment: "NetNewsWire Version (Build BUILD)")
				}
			}
			.navigationTitle(Text("label.text.settings", comment: "Settings"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .close) {
						dismiss()
					}
				}
			}
		}
    }
}

#Preview {
    SettingsView()
}
