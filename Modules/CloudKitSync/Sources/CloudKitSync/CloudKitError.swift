//
//  CloudKitError.swift
//  RSCore
//
//  Created by Maurice Parker on 3/26/20.
//  Copyright © 2020 Ranchero Software, LLC. All rights reserved.
//
// Derived from https://github.com/caiyue1993/IceCream

import Foundation
import CloudKit
import Localizations

public final class CloudKitError: LocalizedError, Sendable {

	public let error: Error

	public init(_ error: Error) {
		self.error = error
	}

	public var errorDescription: String? {
		guard let ckError = error as? CKError else {
			return error.localizedDescription
		}

		switch ckError.code {
		case .alreadyShared:
			return Localizations.labelTextAlreadySharedARecordOrShareCannotBeSavedBecauseDoingSoWouldCauseTheSameHierarchyOfRecordsToExistInMultipleShares
		case .assetFileModified:
			return Localizations.labelTextAssetFileModifiedTheContentOfTheSpecifiedAssetFileWasModifiedWhileBeingSaved
		case .assetFileNotFound:
			return Localizations.labelTextAssetFileNotFoundTheSpecifiedAssetFileIsNotFound
		case .badContainer:
			return Localizations.labelTextBadContainerTheSpecifiedContainerIsUnknownOrUnauthorized
		case .badDatabase:
			return Localizations.labelTextBadDatabaseTheOperationCouldNotBeCompletedOnTheGivenDatabase
		case .batchRequestFailed:
			return Localizations.labelTextBatchRequestFailedTheEntireBatchWasRejected
		case .changeTokenExpired:
			return Localizations.labelTextChangeTokenExpiredThePreviousServerChangeTokenIsTooOld
		case .constraintViolation:
			return Localizations.labelTextConstraintViolationTheServerRejectedTheRequestBecauseOfAConflictWithAUniqueField
		case .incompatibleVersion:
			return Localizations.labelTextIncompatibleVersionYourAppVersionIsOlderThanTheOldestVersionAllowed
		case .internalError:
			return Localizations.labelTextInternalErrorANonrecoverableErrorWasEncounteredByCloudkit
		case .invalidArguments:
			return Localizations.labelTextInvalidArgumentsTheSpecifiedRequestContainsBadInformation
		case .limitExceeded:
			return Localizations.labelTextLimitExceededTheRequestToTheServerIsTooLarge
		case .managedAccountRestricted:
			return Localizations.labelTextManagedAccountRestrictedTheRequestWasRejectedDueToAManagedAccountRestriction
		case .missingEntitlement:
			return Localizations.labelTextMissingEntitlementTheAppIsMissingARequiredEntitlement
		case .networkUnavailable:
			return Localizations.labelTextNetworkUnavailableTheInternetConnectionAppearsToBeOffline
		case .networkFailure:
			return Localizations.labelTextNetworkFailureTheInternetConnectionAppearsToBeOffline
		case .notAuthenticated:
			return Localizations.labelTextNotAuthenticatedToUseTheIcloudAccountYouMustEnableIcloudDriveGoToDeviceSettingsSignInToIcloudThenInTheAppSettingsBeSureTheIcloudDriveFeatureIsEnabled
		case .operationCancelled:
			return Localizations.labelTextOperationCancelledTheOperationWasExplicitlyCanceled
		case .partialFailure:
			return Localizations.labelTextPartialFailureSomeItemsFailedButTheOperationSucceededOverall
		case .participantMayNeedVerification:
			return Localizations.labelTextParticipantMayNeedVerificationYouAreNotAMemberOfTheShare
		case .permissionFailure:
			return Localizations.labelTextPermissionFailureToUseThisAppYouMustEnableIcloudDriveGoToDeviceSettingsSignInToIcloudThenInTheAppSettingsBeSureTheIcloudDriveFeatureIsEnabled
		case .quotaExceeded:
			return Localizations.labelTextQuotaExceededSavingWouldExceedYourCurrentIcloudStorageQuota
		case .referenceViolation:
			return Localizations.labelTextReferenceViolationTheTargetOfARecordSParentOrShareReferenceWasNotFound
		case .requestRateLimited:
			return Localizations.labelTextRequestRateLimitedTransfersToAndFromTheServerAreBeingRateLimitedAtThisTime
		case .serverRecordChanged:
			return Localizations.labelTextServerRecordChangedTheRecordWasRejectedBecauseTheVersionOnTheServerIsDifferent
		case .serverRejectedRequest:
			return Localizations.labelTextServerRejectedRequest
		case .serverResponseLost:
			return Localizations.labelTextServerResponseLost
		case .serviceUnavailable:
			return Localizations.labelTextServiceUnavailablePleaseTryAgain
		case .tooManyParticipants:
			return Localizations.labelTextTooManyParticipantsAShareCannotBeSavedBecauseTooManyParticipantsAreAttachedToTheShare
		case .unknownItem:
			return Localizations.labelTextUnknownItemTheSpecifiedRecordDoesNotExist
		case .userDeletedZone:
			return Localizations.labelTextUserDeletedZoneTheUserHasDeletedThisZoneFromTheSettingsUi
		case .zoneBusy:
			return Localizations.labelTextZoneBusyTheServerIsTooBusyToHandleTheZoneOperation
		case .zoneNotFound:
			return Localizations.labelTextZoneNotFoundTheSpecifiedRecordZoneDoesNotExistOnTheServer
		default:
			return Localizations.labelTextUnhandledError
		}
	}

}
