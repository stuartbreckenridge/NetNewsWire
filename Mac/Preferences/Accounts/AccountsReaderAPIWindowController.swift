//
//  AccountsAddFeedbinWindowController.swift
//  NetNewsWire
//
//  Created by Maurice Parker on 5/2/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import AppKit
import Account
import RSWeb
import Secrets
import Localizations

final class AccountsReaderAPIWindowController: NSWindowController {

	@IBOutlet var titleImageView: NSImageView!
	@IBOutlet var titleLabel: NSTextField!

	@IBOutlet var gridView: NSGridView!
	@IBOutlet var progressIndicator: NSProgressIndicator!
	@IBOutlet var usernameTextField: NSTextField!
	@IBOutlet var apiURLTextField: NSTextField!
	@IBOutlet var passwordTextField: NSSecureTextField!
	@IBOutlet var createAccountButton: NSButton!
	@IBOutlet var errorMessageLabel: NSTextField!
	@IBOutlet var actionButton: NSButton!
	@IBOutlet var noAccountTextField: NSTextField!

	var account: Account?
	var accountType: AccountType?

	private weak var hostWindow: NSWindow?

	convenience init() {
		self.init(windowNibName: NSNib.Name("AccountsReaderAPI"))
	}

	override func windowDidLoad() {
		if let accountType = accountType {
			switch accountType {
			case .freshRSS:
				titleImageView.image = Assets.Images.accountFreshRSS
				titleLabel.stringValue = Localizations.labelTextSignInToYourFreshrssAccount
				noAccountTextField.stringValue = Localizations.labelTextDontHaveAFreshrssInstance
				createAccountButton.title = Localizations.labelTextFindOutMore
				apiURLTextField.placeholderString = Localizations.labelTextHttpsFreshRssNetApiGreaderPhp
			case .inoreader:
				titleImageView.image = Assets.Images.accountInoreader
				titleLabel.stringValue = Localizations.labelTextSignInToYourInoreaderAccount
				gridView.row(at: 2).isHidden = true
				noAccountTextField.stringValue = Localizations.labelTextDontHaveAnInoreaderAccount
			case .bazQux:
				titleImageView.image = Assets.Images.accountBazQux
				titleLabel.stringValue = Localizations.labelTextSignInToYourBazquxAccount
				gridView.row(at: 2).isHidden = true
				noAccountTextField.stringValue = Localizations.labelTextDontHaveABazquxAccount
			case .theOldReader:
				titleImageView.image = Assets.Images.accountTheOldReader
				titleLabel.stringValue = Localizations.labelTextSignInToYourTheOldReaderAccount
				gridView.row(at: 2).isHidden = true
				noAccountTextField.stringValue = Localizations.labelTextDontHaveATheOldReaderAccount
			default:
				break
			}
		}

		if let account = account, let credentials = try? account.retrieveCredentials(type: .readerBasic) {
			usernameTextField.stringValue = credentials.username
			apiURLTextField.stringValue = account.endpointURL?.absoluteString ?? ""
			actionButton.title = Localizations.labelTextUpdate
		} else {
			actionButton.title = Localizations.labelTextCreate
		}

		enableAutofill()
		usernameTextField.becomeFirstResponder()
	}

	// MARK: API

	func runSheetOnWindow(_ hostWindow: NSWindow, completion: ((NSApplication.ModalResponse) -> Void)? = nil) {
		guard let window else {
			return
		}

		self.hostWindow = hostWindow
		hostWindow.beginSheet(window, completionHandler: completion)
	}

	// MARK: Actions

	@IBAction func cancel(_ sender: Any) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.cancel)
	}

	@IBAction func action(_ sender: Any) {
		self.errorMessageLabel.stringValue = ""

		guard !usernameTextField.stringValue.isEmpty && !passwordTextField.stringValue.isEmpty else {
			self.errorMessageLabel.stringValue = Localizations.labelTextUsernamePasswordAndApiUrlAreRequired
			return
		}

		guard let accountType = accountType, !(accountType == .freshRSS && apiURLTextField.stringValue.isEmpty) else {
			self.errorMessageLabel.stringValue = Localizations.labelTextUsernamePasswordAndApiUrlAreRequired
			return
		}

		guard account != nil || !AccountManager.shared.duplicateServiceAccount(type: accountType, username: usernameTextField.stringValue) else {
			self.errorMessageLabel.stringValue = Localizations.labelTextThereIsAlreadyAnAccountOfThisTypeWithThatUsernameCreated
			return
		}

		let apiURL: URL
		switch accountType {
		case .freshRSS:
			guard let inputURL = URL(string: apiURLTextField.stringValue) else {
				self.errorMessageLabel.stringValue = Localizations.labelTextInvalidApiUrl
				return
			}
			apiURL = inputURL
		case .inoreader:
			apiURL =  URL(string: ReaderAPIVariant.inoreader.host)!
		case .bazQux:
			apiURL =  URL(string: ReaderAPIVariant.bazQux.host)!
		case .theOldReader:
			apiURL =  URL(string: ReaderAPIVariant.theOldReader.host)!
		default:
			self.errorMessageLabel.stringValue = Localizations.labelTextUnrecognizedAccountType
			return
		}

		Task { @MainActor in
			actionButton.isEnabled = false
			progressIndicator.isHidden = false
			progressIndicator.startAnimation(self)

			@MainActor func stopAnimation() {
				actionButton.isEnabled = true
				progressIndicator.isHidden = true
				progressIndicator.stopAnimation(self)
			}

			let credentials = Credentials(type: .readerBasic, username: usernameTextField.stringValue, secret: passwordTextField.stringValue)
			do {
				let validatedCredentials = try await Account.validateCredentials(type: accountType, credentials: credentials, endpoint: apiURL)
				stopAnimation()

				guard let validatedCredentials else {
					errorMessageLabel.stringValue = Localizations.labelTextInvalidEmailPasswordCombination
					return
				}

				if account == nil {
					account = AccountManager.shared.createAccount(type: accountType)
				}

				do {
					account?.endpointURL = apiURL

					try account?.removeCredentials(type: .readerBasic)
					try account?.removeCredentials(type: .readerAPIKey)
					try account?.storeCredentials(credentials)
					try account?.storeCredentials(validatedCredentials)

					do {
						try await account?.refreshAll()
					} catch {
						NSApplication.shared.presentError(error)
					}

					hostWindow?.endSheet(window!, returnCode: NSApplication.ModalResponse.OK)
				} catch {
					errorMessageLabel.stringValue = Localizations.labelTextKeychainErrorWhileStoringCredentials
				}

			} catch {
				stopAnimation()
				errorMessageLabel.stringValue = Localizations.labelTextNetworkErrorTryAgainLater
			}
		}
	}

	@IBAction func createAccountWithProvider(_ sender: Any) {
		switch accountType {
		case .freshRSS:
			NSWorkspace.shared.open(URL(string: "https://freshrss.org")!)
		case .inoreader:
			NSWorkspace.shared.open(URL(string: "https://www.inoreader.com")!)
		case .bazQux:
			NSWorkspace.shared.open(URL(string: "https://bazqux.com")!)
		case .theOldReader:
			NSWorkspace.shared.open(URL(string: "https://theoldreader.com")!)
		default:
			return
		}
	}

	// MARK: Autofill
	func enableAutofill() {
		usernameTextField.contentType = .username
		passwordTextField.contentType = .password
	}

}
