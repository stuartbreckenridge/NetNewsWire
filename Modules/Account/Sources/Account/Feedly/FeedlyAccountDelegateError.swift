//
//  FeedlyAccountDelegateError.swift
//  Account
//
//  Created by Kiel Gillard on 9/10/19.
//  Copyright © 2019 Ranchero Software, LLC. All rights reserved.
//

import Foundation
import Localizations

enum FeedlyAccountDelegateError: LocalizedError {
	case notLoggedIn
	case unexpectedResourceID(String)
	case unableToAddFolder(String)
	case unableToRenameFolder(String, String)
	case unableToRemoveFolder(String)
	case unableToMoveFeedBetweenFolders(String, String, String) // feedName, sourceFolderName, destinationFolderName
	case addFeedChooseFolder
	case addFeedInvalidFolder(String) // folderName
	case unableToRenameFeed(String, String)
	case unableToRemoveFeed(String)

	var errorDescription: String? {
		switch self {
		case .notLoggedIn:
			return Localizations.labelTextPleaseAddTheFeedlyAccountAgainIfThisProblemPersistsOpenKeychainAccessAndDeleteAllFeedlyComEntriesThenTryAgain

		case .unexpectedResourceID(let resourceId):
			let template = Localizations.labelTextCouldNotEncodeTheIdentifier
			return String(format: template, resourceId)

		case .unableToAddFolder(let name):
			let template = Localizations.labelTextCouldNotCreateAFolderNamed
			return String(format: template, name)

		case .unableToRenameFolder(let from, let to):
			let template = Localizations.labelTextCouldNotRenameTo
			return String(format: template, from, to)

		case .unableToRemoveFolder(let name):
			let template = Localizations.labelTextCouldNotRemoveTheFolderNamed
			return String(format: template, name)

		case .unableToMoveFeedBetweenFolders(let feedName, _, let destinationFolderName):
			let template = Localizations.labelTextCouldNotMoveTo
			return String(format: template, feedName, destinationFolderName)

		case .addFeedChooseFolder:
			return Localizations.labelTextPleaseChooseAFolderToContainTheFeed

		case .addFeedInvalidFolder(let folderName):
			let template = Localizations.labelTextFeedsCannotBeAddedToTheFolder
			return String(format: template, folderName)

		case .unableToRenameFeed(let from, let to):
			let template = Localizations.labelTextCouldNotRenameTo
			return String(format: template, from, to)

		case .unableToRemoveFeed(let feedName):
			let template = Localizations.labelTextCouldNotRemove
			return String(format: template, feedName)
		}
	}

	var recoverySuggestion: String? {
		switch self {
		case .notLoggedIn:
			return nil

		case .unexpectedResourceID:
			let template = Localizations.labelTextPleaseContactNetnewswireSupport
			return String(format: template)

		case .unableToAddFolder:
			return nil

		case .unableToRenameFolder:
			return nil

		case .unableToRemoveFolder:
			return nil

		case .unableToMoveFeedBetweenFolders(let feedName, let sourceFolderName, let destinationFolderName):
			let template = Localizations.labelTextMayBeInBothAnd
			return String(format: template, feedName, sourceFolderName, destinationFolderName)

		case .addFeedChooseFolder:
			return nil

		case .addFeedInvalidFolder:
			return Localizations.labelTextPleaseChooseADifferentFolderToContainTheFeed

		case .unableToRemoveFeed:
			return nil

		case .unableToRenameFeed:
			return nil
		}
	}
}
