//
//  ReaderAPIAccountViewController.swift
//  NetNewsWire-iOS
//
//  Created by Stuart Breckenridge on 25/10/20.
//  Copyright © 2020 Ranchero Software. All rights reserved.
//

import UIKit
import SafariServices
import RSCore
import RSWeb
import Account
import Secrets
import Localizations

final class ReaderAPIAccountViewController: UITableViewController {
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var cancelBarButtonItem: UIBarButtonItem!
	@IBOutlet var usernameTextField: UITextField!
	@IBOutlet var passwordTextField: UITextField!
	@IBOutlet var apiURLTextField: UITextField!
	@IBOutlet var showHideButton: UIButton!
	@IBOutlet var actionButton: UIButton!
	@IBOutlet var footerLabel: UILabel!
	@IBOutlet var signUpButton: UIButton!

	weak var account: Account?
	var accountType: AccountType?
	weak var delegate: AddAccountDismissDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
		setupFooter()

		activityIndicator.isHidden = true
		usernameTextField.delegate = self
		passwordTextField.delegate = self

		if let unwrappedAccount = account,
		   let credentials = try? retrieveCredentialsForAccount(for: unwrappedAccount) {
			actionButton.setTitle(Localizations.labelTextUpdateCredentials, for: .normal)
			actionButton.isEnabled = true
			usernameTextField.text = credentials.username
			passwordTextField.text = credentials.secret
		} else {
			actionButton.setTitle(Localizations.labelTextAddAccount, for: .normal)
		}

		if let unwrappedAccountType = accountType {
			switch unwrappedAccountType {
			case .freshRSS:
				title = Localizations.labelTextFreshrss
				apiURLTextField.placeholder = Localizations.labelTextApiUrlHttpsFreshRssNetApiGreaderPhp
			case .inoreader:
				title = Localizations.labelTextInoreader
			case .bazQux:
				title = Localizations.labelTextBazqux
			case .theOldReader:
				title = Localizations.labelTextTheOldReader
			default:
				title = ""
			}
		}

		NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: UITextField.textDidChangeNotification, object: usernameTextField)
		NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: UITextField.textDidChangeNotification, object: passwordTextField)

		tableView.register(ImageHeaderView.self, forHeaderFooterViewReuseIdentifier: "SectionHeader")

    }

	private func setupFooter() {
		switch accountType {
		case .bazQux:
			footerLabel.text = Localizations.labelTextSignInToYourBazquxAccountAndSyncYourFeedsAcrossYourDevicesYourUsernameAndPasswordWillBeEncryptedAndStoredInKeychainDontHaveABazquxAccount
			signUpButton.setTitle(Localizations.labelTextSignUpHere, for: .normal)
		case .inoreader:
			footerLabel.text = Localizations.labelTextSignInToYourInoreaderAccountAndSyncYourFeedsAcrossYourDevicesYourUsernameAndPasswordWillBeEncryptedAndStoredInKeychainDontHaveAnInoreaderAccount
			signUpButton.setTitle(Localizations.labelTextSignUpHere, for: .normal)
		case .theOldReader:
			footerLabel.text = Localizations.labelTextSignInToYourTheOldReaderAccountAndSyncYourFeedsAcrossYourDevicesYourUsernameAndPasswordWillBeEncryptedAndStoredInKeychainDontHaveATheOldReaderAccount
			signUpButton.setTitle(Localizations.labelTextSignUpHere, for: .normal)
		case .freshRSS:
			footerLabel.text = Localizations.labelTextSignInToYourFreshrssInstanceAndSyncYourFeedsAcrossYourDevicesYourUsernameAndPasswordWillBeEncryptedAndStoredInKeychainDontHaveAnFreshrssInstance
			signUpButton.setTitle(Localizations.labelTextFindOutMore2, for: .normal)
		default:
			return
		}
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return section == 0 ? ImageHeaderView.rowHeight : super.tableView(tableView, heightForHeaderInSection: section)
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if section == 0 {
			let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader") as! ImageHeaderView
			headerView.imageView.image = headerViewImage()
			return headerView
		} else {
			return super.tableView(tableView, viewForHeaderInSection: section)
		}
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			switch accountType {
			case .freshRSS:
				return 3
			default:
				return 2
			}
		default:
			return 1
		}
	}

	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	@IBAction func showHidePassword(_ sender: Any) {
		if passwordTextField.isSecureTextEntry {
			passwordTextField.isSecureTextEntry = false
			showHideButton.setTitle("Hide", for: .normal)
		} else {
			passwordTextField.isSecureTextEntry = true
			showHideButton.setTitle("Show", for: .normal)
		}
	}

	@IBAction func action(_ sender: Any) {
		guard validateDataEntry(), let type = accountType else {
			return
		}

		let username = usernameTextField.text!
		let password = passwordTextField.text!
		let url = apiURL()!

		// When you fill in the email address via auto-complete it adds extra whitespace
		let trimmedUsername = username.trimmingCharacters(in: .whitespaces)

		guard account != nil || !AccountManager.shared.duplicateServiceAccount(type: type, username: trimmedUsername) else {
			showError(Localizations.labelTextThereIsAlreadyAnAccountOfThatTypeWithThatUsernameCreated)
			return
		}

		Task { @MainActor in
			startAnimatingActivityIndicator()
			disableNavigation()

			@MainActor func stopAnimation() {
				stopAnimatingActivityIndicator()
				enableNavigation()
			}

			let credentials = Credentials(type: .readerBasic, username: trimmedUsername, secret: password)
			do {
				let validatedCredentials = try await Account.validateCredentials(type: type, credentials: credentials, endpoint: url)
				stopAnimation()

				if let validatedCredentials {
					if account == nil {
						account = AccountManager.shared.createAccount(type: type)
					}

					do {
						account?.endpointURL = url

						try? account?.removeCredentials(type: .readerBasic)
						try? account?.removeCredentials(type: .readerAPIKey)
						try account?.storeCredentials(credentials)
						try account?.storeCredentials(validatedCredentials)

						dismiss(animated: true, completion: nil)

						do {
							try await account?.refreshAll()
						} catch {
							showError(error.localizedDescription)
						}

						delegate?.dismiss()
					} catch {
						showError(Localizations.labelTextKeychainErrorWhileStoringCredentials)
					}
				} else {
					showError(Localizations.labelTextInvalidUsernamePasswordCombination)
				}
			} catch {
				stopAnimation()
				showError(error.localizedDescription)
			}
		}
	}

	private func retrieveCredentialsForAccount(for account: Account) throws -> Credentials? {
		switch accountType {
		case .bazQux, .inoreader, .theOldReader, .freshRSS:
			return try account.retrieveCredentials(type: .readerBasic)
		default:
			return nil
		}
	}

	private func headerViewImage() -> UIImage? {
		if let accountType {
			switch accountType {
			case .bazQux:
				return Assets.Images.accountBazQux
			case .inoreader:
				return Assets.Images.accountInoreader
			case .theOldReader:
				return Assets.Images.accountTheOldReader
			case .freshRSS:
				return Assets.Images.accountFreshRSS
			default:
				return nil
			}
		}
		return nil
	}

	private func validateDataEntry() -> Bool {
		switch accountType {
		case .freshRSS:
			if !usernameTextField.hasText || !passwordTextField.hasText || !apiURLTextField.hasText {
				showError(Localizations.labelTextUsernamePasswordAndApiUrlAreRequired2)
				return false
			}
			guard URL(string: apiURLTextField.text!) != nil else {
				showError(Localizations.labelTextInvalidApiUrl)
				return false
			}
		default:
			if !usernameTextField.hasText || !passwordTextField.hasText {
				showError(Localizations.labelTextUsernameAndPasswordAreRequired)
				return false
			}
		}
		return true
	}

	@IBAction func signUpWithProvider(_ sender: Any) {
		var url: URL!
		switch accountType {
		case .bazQux:
			url = URL(string: "https://bazqux.com")!
		case .inoreader:
			url = URL(string: "https://www.inoreader.com")!
		case .theOldReader:
			url = URL(string: "https://theoldreader.com")!
		case .freshRSS:
			url = URL(string: "https://freshrss.org")!
		default:
			return
		}
		let safari = SFSafariViewController(url: url)
		safari.modalPresentationStyle = .currentContext
		self.present(safari, animated: true, completion: nil)
	}

	private func apiURL() -> URL? {
		switch accountType {
		case .freshRSS:
			return URL(string: apiURLTextField.text!)!
		case .inoreader:
			return URL(string: ReaderAPIVariant.inoreader.host)!
		case .bazQux:
			return URL(string: ReaderAPIVariant.bazQux.host)!
		case .theOldReader:
			return URL(string: ReaderAPIVariant.theOldReader.host)!
		default:
			return nil
		}
	}

	@objc func textDidChange(_ note: Notification) {
		actionButton.isEnabled = !(usernameTextField.text?.isEmpty ?? false)
	}

	private func showError(_ message: String) {
		presentError(title: "Error", message: message)
	}

	private func enableNavigation() {
		self.cancelBarButtonItem.isEnabled = true
		self.actionButton.isEnabled = true
	}

	private func disableNavigation() {
		cancelBarButtonItem.isEnabled = false
		actionButton.isEnabled = false
	}

	private func startAnimatingActivityIndicator() {
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
	}

	private func stopAnimatingActivityIndicator() {
		self.activityIndicator.isHidden = true
		self.activityIndicator.stopAnimating()
	}
}

extension ReaderAPIAccountViewController: UITextFieldDelegate {

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}
