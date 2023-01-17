//
//  AddMastodonSelectionView.swift
//  NetNewsWire
//
//  Created by Stuart Breckenridge on 17/01/2023.
//  Copyright © 2023 Ranchero Software. All rights reserved.
//

import SwiftUI

struct AddMastodonSelectionView: View {
    
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		NavigationView {
			List {
				NavigationLink {
					AddMastodonFeedView(feedType: .user)
				} label: {
					VStack(alignment: .leading, spacing: 4) {
						Text("label.text.add-mastodon-user-feed", comment: "Add a Mastodon User's Feed")
						Text("label.text.mastodon-user-feed-explainer", comment: "Follow the specified user's Mastodon feed")
							.font(.caption)
					}
				}
				
				NavigationLink {
					AddMastodonFeedView(feedType: .hashtag)
				} label: {
					VStack(alignment: .leading, spacing: 4) {
						Text("label.text.add-mastodon-tag", comment: "Follow a #Hashtag")
						Text("label.text.mastodon-tag-feed-explainer", comment: "Follow the specified #hashtag")
							.font(.caption)
					}
				}
			}
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button {
						dismiss()
					} label: {
						Text("button.title.cancel", comment: "Cancel")
					}
				}
			}
			.navigationBarTitleDisplayMode(.inline)
			.navigationTitle(Text("navigation.title.select-mastodon-type", comment: "Select Mastodon Feed Type"))
			.onReceive(NotificationCenter.default.publisher(for: .UserDidAddFeed)) { _ in
				dismiss()
			}
		}
    }
}

struct AddMastodonSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        AddMastodonSelectionView()
    }
}
