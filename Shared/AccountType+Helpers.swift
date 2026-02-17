//
//  AccountType+Helpers.swift
//  NetNewsWire
//
//  Created by Stuart Breckenridge on 27/10/20.
//  Copyright © 2020 Ranchero Software. All rights reserved.
//

import Foundation
import Account
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI
import Localizations

extension AccountType {

	// TODO: Move this to the Account Package.

	func localizedAccountName() -> String {

		switch self {
		case .onMyMac:
			return Localizations.accountNameOnMyDevice
		case .bazQux:
			return Localizations.labelTextBazqux
		case .cloudKit:
			return Localizations.labelTextIcloud
		case .feedbin:
			return Localizations.labelTextFeedbin
		case .feedly:
			return Localizations.labelTextFeedly
		case .freshRSS:
			return Localizations.labelTextFreshrss
		case .inoreader:
			return Localizations.labelTextInoreader
		case .newsBlur:
			return Localizations.labelTextNewsblur
		case .theOldReader:
			return Localizations.labelTextTheOldReader
		}
	}

	// MARK: - SwiftUI Images
	@MainActor func image() -> Image {
		switch self {
		case .onMyMac:
			// If it's the multiplatform app, the asset catalog contains assets for 
			#if os(macOS)
			return Image("accountLocal")
			#else
			if UIDevice.current.userInterfaceIdiom == .pad {
				return Image("accountLocalPad")
			} else {
				return Image("accountLocalPhone")
			}
			#endif
		case .bazQux:
			return Image("accountBazQux")
		case .cloudKit:
			return Image("accountCloudKit")
		case .feedbin:
			return Image("accountFeedbin")
		case .feedly:
			return Image("accountFeedly")
		case .freshRSS:
			return Image("accountFreshRSS")
		case .inoreader:
			return Image("accountInoreader")
		case .newsBlur:
			return Image("accountNewsBlur")
		case .theOldReader:
			return Image("accountTheOldReader")
		}
	}

}
