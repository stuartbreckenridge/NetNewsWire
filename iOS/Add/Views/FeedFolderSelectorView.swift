//
//  FeedFolderSelectorView.swift
//  NetNewsWire-iOS
//
//  Created by Stuart Breckenridge on 17/01/2023.
//  Copyright © 2023 Ranchero Software. All rights reserved.
//

import SwiftUI
import Account
import RSCore

struct FeedFolderSelectorView: View {
    
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject private var viewModel: MastodonViewModel
	
	var body: some View {
		NavigationView {
			List {
				ForEach(0..<viewModel.containers.count, id: \.self, content: { index in
					if let _ = (viewModel.containers[index] as? DisplayNameProvider)?.nameForDisplay {
						containerRow(viewModel.containers[index])
							.onTapGesture {
								viewModel.selectedFolderIndex = index
								dismiss()
							}
					}
				})
			}
			.listStyle(.plain)
			.navigationBarTitle(Text("navigation.title.select-folder", comment: "Select Folder"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button {
						dismiss()
					} label: {
						Text("button.title.cancel", comment: "Cancel")
					}
				}
			}
		}
    }
	
	private func containerRow(_ container: Container) -> some View {
		HStack {
			if container is Folder {
				Image(uiImage: AppAssets.masterFolderImage.image)
					.resizable()
					.renderingMode(.template)
					.aspectRatio(contentMode: .fit)
					.frame(width: 20)
					.foregroundColor(.accentColor)
				Text(container.account!.nameForDisplay + " / " + (container as! DisplayNameProvider).nameForDisplay)
				Spacer()
				if viewModel.containers[viewModel.selectedFolderIndex].containerID! == container.containerID! {
					Image(systemName: "checkmark")
						.foregroundColor(.accentColor)
				}
			} else {
				Image(uiImage: container.account!.smallIcon!.image)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 25)
				Text((container as! DisplayNameProvider).nameForDisplay)
				Spacer()
				if viewModel.containers[viewModel.selectedFolderIndex].containerID! == container.containerID! {
					Image(systemName: "checkmark")
						.foregroundColor(.accentColor)
				}
			}
		}.padding(.leading, container is Folder ? 30 : 0)
		
	}
}

