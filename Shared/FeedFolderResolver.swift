//
//  FeedFolderResolver.swift
//  NetNewsWire
//
//  Created by Stuart Breckenridge on 17/01/2023.
//  Copyright © 2023 Ranchero Software. All rights reserved.
//

import Foundation
import Account
import RSCore


/// View models for adding feeds and folders inherit from the `FeedFolderResolver`class
/// as it provides standard bulding blocks for the feeds and folders pickers
/// and selection tracking.
public class FeedFolderResolver: ObservableObject {
	
	@Published var selectedFolderIndex: Int = 0
	@Published var containers: [Container] = []
	
	init() {
		for account in AccountManager.shared.sortedActiveAccounts {
			containers.append(account)
			if let sortedFolders = account.sortedFolders {
				containers.append(contentsOf: sortedFolders)
			}
		}
	}
	
	func accountAndFolderFromContainer(_ container: Container) -> AccountAndFolderSpecifier? {
		if let account = container as? Account {
			return AccountAndFolderSpecifier(account: account, folder: nil)
		}
		if let folder = container as? Folder, let account = folder.account {
			return AccountAndFolderSpecifier(account: account, folder: folder)
		}
		return nil
	}
	
	func smallIconImage(for container: Container) -> RSImage? {
		if let smallIconProvider = container as? SmallIconProvider {
			return smallIconProvider.smallIcon?.image
		}
		return nil
	}
	
}

public struct AccountAndFolderSpecifier {
	public let account: Account
	public let folder: Folder?
}
