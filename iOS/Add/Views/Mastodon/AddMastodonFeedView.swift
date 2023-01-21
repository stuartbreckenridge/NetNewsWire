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
	@FocusState private var userNameOrHashtagFocussed
	@FocusState private var serverFocussed
	@FocusState private var titleFocussed
	var feedType: MastodonFeedType
	
	init(feedType: MastodonFeedType) {
		self.feedType = feedType
	}
	
	var body: some View {
		Form {
			Section {
				userNameOrHashTagTextField
					.onAppear {
						userNameOrHashtagFocussed = true
					}
				instanceTextField
				titleTextField
				folderSelectorButton
			}
			
			if viewModel.showServerSuggestions {
				serverSuggestions
			}
		}
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				HStack {
					if viewModel.showProgressIndicator {
						ProgressView()
					}
					addButton
				}
			}
			
			ToolbarItem(placement: .navigationBarLeading) {
				dismissButton
			}
		}
		.navigationBarBackButtonHidden()
		.navigationTitle(Text("navigation.title.feed-details", comment: "Feed Details"))
		
		.alert(Text("alert.title.error", comment: "Error"),
			   isPresented: $viewModel.apiError.0,
			   actions: {},
			   message: {
			Text(viewModel.apiError.1?.localizedDescription ?? "Unknown Error")
		})
		.task {
			await viewModel.refreshServerList()
		}
    }
	
	
	var userNameOrHashTagTextField: some View {
		TextField(text: $viewModel.userNameOrHashtag) {
			if feedType == .hashtag {
				Text("textfield.placeholder.mastodon-hashtag", comment: "#hashtag")
			} else {
				Text("textfield.placeholder.mastodon-user", comment: "Username")
			}
		}
		.focused($userNameOrHashtagFocussed)
		.textInputAutocapitalization(.never)
		.autocorrectionDisabled(true)
	}
	
	var instanceTextField: some View {
		TextField(text: $viewModel.server) {
			Text("textfield.mastodon.server", comment: "Instance")
		}
		.focused($serverFocussed)
		.textInputAutocapitalization(.never)
		.autocorrectionDisabled(true)
		.onChange(of: viewModel.server) { newValue in
			viewModel.searchFor(newValue)
			if (viewModel.server.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 || viewModel.filteredServers.count < 1 || viewModel.filteredServers.first!.domain == viewModel.server) {
				viewModel.showServerSuggestions = false
			} else {
				viewModel.showServerSuggestions = true
			}
		}
	}
	
	var titleTextField: some View {
		TextField(text: $viewModel.optionalTitle) {
			Text("textfield.placeholder.feed-title", comment: "Title (Optional)")
		}
		.textInputAutocapitalization(.never)
		.autocorrectionDisabled(true)
		.focused($titleFocussed)
	}
	
	
	var folderSelectorButton: some View {
		Button {
			viewModel.showFeedFolderSelector = true
		} label: {
			HStack {
				Text("Folder")
				Spacer()
				nameForContainer(viewModel.containers[viewModel.selectedFolderIndex])
			}
			.foregroundColor(.primary)
		}
		.sheet(isPresented: $viewModel.showFeedFolderSelector, content: {
			FeedFolderSelectorView()
				.environmentObject(viewModel)
		})
	}
	
	var serverSuggestions: some View {
		Section(header: Text("label.text.suggested-servers", comment: "Suggested Servers")) {
			ForEach(viewModel.filteredServers) { svr in
				Button {
					serverFocussed = false
					viewModel.server = svr.domain
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
	
	var addButton: some View {
		Button {
			resignFocus()
			Task {
				if feedType == .hashtag {
					do {
						var title: String?
						if viewModel.optionalTitle.trimmingWhitespace.count > 0 {
							title = viewModel.optionalTitle
						}
						try await viewModel.followTag(viewModel.userNameOrHashtag, server: viewModel.server, title: title)
						dismiss()
					} catch {
						viewModel.apiError = (true, error)
					}
				} else {
					do {
						var title: String?
						if viewModel.optionalTitle.trimmingWhitespace.count > 0 {
							title = viewModel.optionalTitle
						}
						try await viewModel.followUser(viewModel.userNameOrHashtag, server: viewModel.server, title: title)
						dismiss()
					} catch {
						viewModel.apiError = (true, error)
					}
				}
			}
		} label: {
			Text("button.title.add", comment: "Add")
		}.disabled(!canAddMastodon())
	}
	
	var dismissButton: some View {
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
	
	private func resignFocus() {
		serverFocussed = false
		userNameOrHashtagFocussed = false
		titleFocussed = false
	}
		
	private func canAddMastodon() -> Bool {
		return viewModel.userNameOrHashtag.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 && viewModel.server.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
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
