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

final class AccountsFeedbinWindowController: NSWindowController {

	@IBOutlet var signInTextField: NSTextField!
	@IBOutlet var noAccountTextField: NSTextField!
	@IBOutlet var createNewAccountButton: NSButton!
	@IBOutlet var progressIndicator: NSProgressIndicator!
	@IBOutlet var usernameTextField: NSTextField!
	@IBOutlet var passwordTextField: NSSecureTextField!
	@IBOutlet var errorMessageLabel: NSTextField!
	@IBOutlet var actionButton: NSButton!

	var account: Account?

	private weak var hostWindow: NSWindow?

	convenience init() {
		self.init(windowNibName: NSNib.Name("AccountsFeedbin"))
	}

	override func windowDidLoad() {
		if let account = account, let credentials = try? account.retrieveCredentials(type: .basic) {
			usernameTextField.stringValue = credentials.username
			actionButton.title = Localizations.labelTextUpdate
			signInTextField.stringValue = Localizations.labelTextUpdateYourFeedbinAccountCredentials
			noAccountTextField.isHidden = true
			createNewAccountButton.isHidden = true
		} else {
			actionButton.title = Localizations.labelTextCreate
			signInTextField.stringValue = Localizations.labelTextSignInToYourFeedbinAccount
		}

		enableAutofill()

		usernameTextField.becomeFirstResponder()
	}

	// MARK: API

	func runSheetOnWindow(_ hostWindow: NSWindow) {
		guard let window else {
			return
		}

		self.hostWindow = hostWindow
		hostWindow.beginSheet(window)
	}

	// MARK: - Actions

	@IBAction func cancel(_ sender: Any) {
		hostWindow!.endSheet(window!, returnCode: NSApplication.ModalResponse.cancel)
	}

	@IBAction func action(_ sender: Any) {
		errorMessageLabel.stringValue = ""

		guard !usernameTextField.stringValue.isEmpty && !passwordTextField.stringValue.isEmpty else {
			errorMessageLabel.stringValue = Localizations.labelTextUsernameAndPasswordRequired
			return
		}

		guard account != nil || !AccountManager.shared.duplicateServiceAccount(type: .feedbin, username: usernameTextField.stringValue) else {
			errorMessageLabel.stringValue = Localizations.labelTextThereIsAlreadyAFeedbinAccountWithThatUsernameCreated
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

			let credentials = Credentials(type: .basic, username: usernameTextField.stringValue, secret: passwordTextField.stringValue)
			do {
				let validatedCredentials = try await Account.validateCredentials(type: .feedbin, credentials: credentials)
				stopAnimation()

				guard let validatedCredentials else {
					errorMessageLabel.stringValue = Localizations.labelTextInvalidEmailPasswordCombination
					return
				}

				if account == nil {
					account = AccountManager.shared.createAccount(type: .feedbin)
				}

				do {
					try account?.removeCredentials(type: .basic)
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
		NSWorkspace.shared.open(URL(string: "https://feedbin.com/signup")!)
	}

	// MARK: Autofill
	func enableAutofill() {
		usernameTextField.contentType = .username
		passwordTextField.contentType = .password
	}
}
