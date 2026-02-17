//
//  AddCloudKitAccount.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 9/22/25.
//  Copyright © 2025 Ranchero Software. All rights reserved.
//

import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
import Localizations
#endif

enum AddCloudKitAccountError: LocalizedError, RecoverableError, Sendable {
	case iCloudDriveMissing

	var errorDescription: String? {
		Localizations.labelTextCantAddIcloudAccount
	}

	var recoverySuggestion: String? {
		#if os(macOS)
		Localizations.labelTextOpenSystemSettingsToConfigureIcloudAndEnableIcloudDrive
		#else
		Localizations.labelTextOpenSettingsToConfigureIcloudAndEnableIcloudDrive
		#endif
	}

	var recoveryOptions: [String] {
		#if os(macOS)
		[Localizations.labelTextOpenSystemSettings, Localizations.labelTextCancel]
		#else
		[Localizations.labelTextOpenSettings, Localizations.labelTextCancel]
		#endif
	}

	func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
		guard recoveryOptionIndex == 0 else {
			return false
		}

		Task { @MainActor in
			AddCloudKitAccountUtilities.openiCloudSettings()
		}

		return true
	}
}

struct AddCloudKitAccountUtilities {
	static var isiCloudDriveEnabled: Bool {
		FileManager.default.ubiquityIdentityToken != nil
	}

	@MainActor static func openiCloudSettings() {
#if os(macOS)
		if let url = URL(string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane") {
			NSWorkspace.shared.open(url)
		}
#else
		if let url = URL(string: "App-prefs:APPLE_ACCOUNT") {
			UIApplication.shared.open(url)
		}
#endif
	}
}
