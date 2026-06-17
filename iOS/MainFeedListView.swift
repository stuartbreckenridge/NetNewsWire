//
//  MainFeedListView.swift
//  NetNewsWire-iOS
//
//  Created by Stuart Breckenridge on 17/06/2026.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import SwiftUI

struct MainFeedListView: View {
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
					//
				} label: {
					Image(systemName: "arrowshape.down.circle")
				}
				Spacer()
				Menu {
					Button {
						//
					} label: {
						Text(verbatim: "Add Folder")
					}
					Button {
						//
					} label: {
						Text(verbatim: "Add Feed")
					}
				} label: {
					Image(systemName: "plus")
				}
			}
		}
    }
}

#Preview {
    MainFeedListView()
}
