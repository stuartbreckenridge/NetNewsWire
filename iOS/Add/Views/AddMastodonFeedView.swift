//
//  AddMastodonFeedView.swift
//  NetNewsWire
//
//  Created by Stuart Breckenridge on 17/01/2023.
//  Copyright © 2023 Ranchero Software. All rights reserved.
//

import SwiftUI
import Account
import RSCore

public enum MastodonFeedType {
	case user, hashtag
}

struct AddMastodonFeedView: View {
    
	@Environment(\.dismiss) private var dismiss
	@StateObject private var viewModel = MastodonViewModel()
	@State private var userNameOrHashtag: String = ""
	@State private var server: String = ""
	@State private var showServerSuggestions: Bool = false
	@State private var selectedFolder: String = ""
	@State private var showFeedFolderSelector: Bool = false
	@FocusState private var userNameOrHashtagFocussed
	@FocusState private var serverFocussed
	var feedType: MastodonFeedType
	
	init(feedType: MastodonFeedType) {
		self.feedType = feedType
	}
	
	var body: some View {
		List {
			Section {
				TextField(text: $userNameOrHashtag) {
					if feedType == .hashtag {
						Text("textfield.placeholder.mastodon-hashtag", comment: "#hashtag")
					} else {
						Text("textfield.placeholder.mastodon-user", comment: "Username")
					}
				}
				.focused($userNameOrHashtagFocussed)
				.textInputAutocapitalization(.never)
				.autocorrectionDisabled(true)
				
				TextField(text: $server) {
					Text("textfield.mastodon.server", comment: "Instance")
				}
				.focused($serverFocussed)
				.textInputAutocapitalization(.never)
				.autocorrectionDisabled(true)
				.onChange(of: server) { newValue in
					viewModel.searchFor(newValue)
					if (server.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 || viewModel.filteredServers.count < 1 || viewModel.filteredServers.first!.domain == server) {
						showServerSuggestions = false
					} else {
						showServerSuggestions = true
					}
				}
				
				Button {
					showFeedFolderSelector = true
				} label: {
					HStack {
						Text("Folder")
						Spacer()
						nameForContainer(viewModel.containers[viewModel.selectedFolderIndex])
					}
					.foregroundColor(.primary)
				}
			}
			
			if showServerSuggestions {
				Section(header: Text("label.text.suggested-servers", comment: "Suggested Servers")) {
					ForEach(viewModel.filteredServers) { svr in
						Button {
							serverFocussed = false
							server = svr.domain
						} label: {
							VStack(alignment: .leading) {
								Text(verbatim: svr.domain)
									.foregroundColor(.accentColor)
									.bold()
								Text(verbatim: svr.description)
									.foregroundColor(.secondary)
									.font(.caption)
									.lineLimit(4)
							}
						}
					}
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				HStack {
					if viewModel.showProgressIndicator {
						ProgressView()
					}
					
					Button {
						serverFocussed = false
						userNameOrHashtagFocussed = false
						Task {
							if feedType == .hashtag {
								do {
									try await viewModel.followTag(userNameOrHashtag, server: server)
									dismiss()
								} catch {
									
								}
								
							} else {
								do {
									try await viewModel.followUser(userNameOrHashtag, server: server)
									dismiss()
								} catch {
									
								}
							}
						}
					} label: {
						Text("button.title.add", comment: "Add")
					}.disabled(!canAddMastodon())
				}
			}
			
			ToolbarItem(placement: .navigationBarLeading) {
				Button {
					dismiss()
				} label: {
					HStack {
						Text(Image(systemName: "chevron.backward"))
							.fontWeight(.semibold)
						Text("button.title.back", comment: "Back")
					}
				}
			}
		}
		.navigationBarBackButtonHidden()
		.navigationTitle(Text("navigation.title.feed-details", comment: "Feed Details"))
		.sheet(isPresented: $showFeedFolderSelector, content: {
			FeedFolderSelectorView()
				.environmentObject(viewModel)
		})
		.task {
			await viewModel.refreshServerList()
		}
    }
	
	private func canAddMastodon() -> Bool {
		return userNameOrHashtag.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 && server.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
	}
	
	private func nameForContainer(_ container: Container) -> Text {
		if container is Folder {
			return Text(container.account!.nameForDisplay + " / " + (container as! DisplayNameProvider).nameForDisplay)
		} else {
			return Text((container as! DisplayNameProvider).nameForDisplay)
		}
	}
}

struct AddMastodonFeedView_Previews: PreviewProvider {
    static var previews: some View {
		AddMastodonFeedView(feedType: .hashtag)
    }
}
