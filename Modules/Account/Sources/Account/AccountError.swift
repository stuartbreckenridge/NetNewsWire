//
//  AccountError.swift
//  NetNewsWire
//
//  Created by Maurice Parker on 5/26/19.
//  Copyright © 2019 Ranchero Software, LLC. All rights reserved.
//

import Foundation
import RSWeb
import Localizations

public enum AccountError: LocalizedError {

	case createErrorNotFound
	case createErrorAlreadySubscribed
	case opmlImportInProgress
	case invalidParameter
	case invalidResponse
	case urlNotFound
	case unknown
	case wrappedError(error: Error, accountID: String, accountName: String)

	public var isCredentialsError: Bool {
		if case .wrappedError(let error, _, _) = self {
			if case TransportError.httpError(let status) = error {
				return isCredentialsError(status: status)
			}
		}
		return false
	}

	@MainActor static func wrapped(_ error: Error, _ account: Account) -> AccountError {
		AccountError.wrappedError(error: error, accountID: account.accountID, accountName: account.nameForDisplay)
	}

	@MainActor public static func account(from error: AccountError?) -> Account? {
		if case let .wrappedError(_, accountID, _) = error {
			return AccountManager.shared.existingAccount(accountID: accountID)
		}
		return nil
	}

	public var errorDescription: String? {
		switch self {
		case .createErrorNotFound:
			return Localizations.labelTextTheFeedCouldntBeFoundAndCantBeAdded
		case .createErrorAlreadySubscribed:
			return Localizations.labelTextYouAreAlreadySubscribedToThisFeedAndCantAddItAgain
		case .opmlImportInProgress:
			return Localizations.labelTextAnOpmlImportForThisAccountIsAlreadyRunning
		case .invalidParameter:
			return Localizations.labelTextCouldntFulfillTheRequestDueToAnInvalidParameter
		case .invalidResponse:
			return Localizations.labelTextThereWasAnInvalidResponseFromTheServer
		case .urlNotFound:
			return Localizations.labelTextTheUrlRequestResultedInANotFoundError
		case .unknown:
			return Localizations.labelTextUnknownError
		case .wrappedError(let error, _, let accountName):
			switch error {
			case TransportError.httpError(let status):
				if isCredentialsError(status: status) {
					let localizedText = Localizations.labelTextYourCredentialsAreInvalidOrExpired
					return NSString.localizedStringWithFormat(localizedText as NSString, accountName) as String
				} else {
					return unknownError(error, accountName)
				}
			default:
				return unknownError(error, accountName)
			}
		}
	}

	public var recoverySuggestion: String? {
		switch self {
		case .createErrorNotFound:
			return nil
		case .createErrorAlreadySubscribed:
			return nil
		case .wrappedError(let error, _, _):
			switch error {
			case TransportError.httpError(let status):
				if isCredentialsError(status: status) {
					return Localizations.labelTextPleaseUpdateYourCredentialsForThisAccountOrEnsureThatYourAccountWithThisServiceIsStillValid
				} else {
					return Localizations.labelTextPleaseTryAgainLater
				}
			default:
				return Localizations.labelTextPleaseTryAgainLater
			}
		default:
			return Localizations.labelTextPleaseTryAgainLater
		}
	}
}

// MARK: Private

private extension AccountError {

	func unknownError(_ error: Error, _ accountName: String) -> String {
		let localizedText = Localizations.labelTextAnErrorOccurredWhileProcessingTheAccount
		return NSString.localizedStringWithFormat(localizedText as NSString, accountName, error.localizedDescription) as String
	}

	func isCredentialsError(status: Int) -> Bool {
		return status == 401  || status == 403
	}

}
