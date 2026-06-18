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
	
	// MARK: App Storage
	
	// MARK: State Objects
	
	// MARK: State
	@State private var showAddFeedView: Bool = false
	@State private var showAddFolderView: Bool = false
	@State private var showCurrentActivityView: Bool = false
	
	// MARK: Bindings
	
	// MARK: Constants
	
	// MARK: Variables

	
	
	var body: some View {
		List {
			//
		}
		.navigationTitle(Text(verbatim: "Feeds"))
		.navigationSubtitle(Text(verbatim: "Last Updated: ..."))
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					//
				} label: {
					Image(systemName: "line.3.horizontal.decrease")
				}
			}
			ToolbarItemGroup(placement: .bottomBar) {
				Button {
					//
				} label: {
					Image(systemName: "gear")
				}
				Button {
					showCurrentActivityView = true
				} label: {
					Image(systemName: "arrowshape.down.circle")
				}
				Spacer()
				Menu {
					Button {
						showAddFolderView = true
					} label: {
						Text(verbatim: "Add Folder")
					}
					Button {
						showAddFeedView = true
					} label: {
						Text(verbatim: "Add Feed")
					}
				} label: {
					Image(systemName: "plus")
				}
			}
		}
		.sheet(isPresented: $showAddFeedView) {
			ContentUnavailableView {
				Text(verbatim: "Add Feed View")
			}
		}
		.sheet(isPresented: $showAddFolderView) {
			ContentUnavailableView {
				Text(verbatim: "Add Folder View")
			}
		}
		.sheet(isPresented: $showCurrentActivityView) {
			NavigationStack {
				CurrentActivityView()
					.presentationDetents([.medium])
					.presentationDragIndicator(.visible)
					.navigationTitle(Text(verbatim: "Current Activity"))
					.navigationBarTitleDisplayMode(.inline)
			}
			
		}
    }
}

#Preview {
    MainFeedListView()
}
