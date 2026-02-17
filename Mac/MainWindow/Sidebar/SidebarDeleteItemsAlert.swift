//
//  SidebarDeleteItemsAlert.swift
//  NetNewsWire
//
//  Created by Maurice Parker on 10/23/20.
//  Copyright © 2020 Ranchero Software. All rights reserved.
//

import AppKit
import RSTree
import Account
import Localizations

enum SidebarDeleteItemsAlert {

	/// Builds a delete confirmation dialog for the supplied nodes
	@MainActor static func build(_ nodes: [Node]) -> NSAlert {
		let alert = NSAlert()
		alert.alertStyle = .warning

		if nodes.count == 1 {
			if let folder = nodes.first?.representedObject as? Folder {
				alert.messageText = Localizations.labelTextDeleteFolder
				let localizedInformativeText = Localizations.labelTextAreYouSureYouWantToDeleteTheFolder
				alert.informativeText = NSString.localizedStringWithFormat(localizedInformativeText as NSString, folder.nameForDisplay) as String
			} else if let sidebarItem = nodes.first?.representedObject as? SidebarItem {
				alert.messageText = Localizations.labelTextDeleteFeed
				let localizedInformativeText = Localizations.labelTextAreYouSureYouWantToDeleteTheFeed
				alert.informativeText = NSString.localizedStringWithFormat(localizedInformativeText as NSString, sidebarItem.nameForDisplay) as String
			}
		} else {
			alert.messageText = Localizations.labelTextDeleteItems
			let localizedInformativeText = Localizations.labelTextAreYouSureYouWantToDeleteTheSelectedItems
			alert.informativeText = NSString.localizedStringWithFormat(localizedInformativeText as NSString, nodes.count) as String
		}

		alert.addButton(withTitle: Localizations.labelTextDelete)
		alert.addButton(withTitle: Localizations.labelTextCancel)

		return alert
	}

}
