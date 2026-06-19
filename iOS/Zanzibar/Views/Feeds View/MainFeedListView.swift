//
//  MainFeedListView.swift
//  NetNewsWire-iOS
//
//  Created by Stuart Breckenridge on 17/06/2026.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import SwiftUI

struct MainFeedListView: View {

	// MARK: Environment
	@Environment(ApplicationCoordinator.self) var coordinator

	// MARK: App Storage

	// MARK: State Objects

	// MARK: State

	// MARK: Bindings

	// MARK: Constants

	// MARK: Variables

	var body: some View {
		@Bindable var coordinator = coordinator

		List {
			//
		}
		.navigationTitle(Text("label.text.feeds", comment: "Feeds"))
		.navigationSubtitle(Text(verbatim: "Last Updated: ..."))
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					coordinator.filterRead.toggle()
				} label: {
					Image(systemName: "line.3.horizontal.decrease")
				}
				.tint(coordinator.filterRead ? .accentColor : .primary)
			}
			ToolbarItemGroup(placement: .bottomBar) {
				Button {
					coordinator.showSettings = true
				} label: {
					Image(systemName: "gear")
				}
				Button {
					coordinator.showCurrentActivity = true
				} label: {
					Image(systemName: "arrowshape.down.circle")
				}
				Spacer()
				Menu {
					Button {
						coordinator.showAddFolder = true
					} label: {
						Text("label.text.add-folder", comment: "Add Folder")
					}
					Button {
						coordinator.showAddFeed = true
					} label: {
						Text("label.text.add-feed", comment: "Add Feed")
					}
				} label: {
					Image(systemName: "plus")
				}
			}
		}
		.sheet(isPresented: $coordinator.showAddFeed) {
			ContentUnavailableView {
				Text(verbatim: "Add Feed View")
			}
		}
		.sheet(isPresented: $coordinator.showAddFolder) {
			ContentUnavailableView {
				Text(verbatim: "Add Folder View")
			}
		}
		.sheet(isPresented: $coordinator.showCurrentActivity) {
			NavigationStack {
				CurrentActivityView()
					.presentationDetents([.medium])
					.presentationDragIndicator(.visible)
					.navigationTitle(Text("label.text.current-activity", comment: "Current Activity"))
					.navigationBarTitleDisplayMode(.inline)
			}

		}
    }
}

#Preview {
    MainFeedListView()
}
