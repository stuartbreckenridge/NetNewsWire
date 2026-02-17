//
//  NewsBlurAccountViewController.swift
//  NetNewsWire
//
//  Created by Anh-Quang Do on 3/9/20.
//  Copyright (c) 2020 Ranchero Software. All rights reserved.
//

import UIKit
import SafariServices
import RSCore
import RSWeb
import Account
import Secrets
import Localizations

final class NewsBlurAccountViewController: UITableViewController {
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var cancelBarButtonItem: UIBarButtonItem!
	@IBOutlet var usernameTextField: UITextField!
	@IBOutlet var passwordTextField: UITextField!
	@IBOutlet var showHideButton: UIButton!
	@IBOutlet var actionButton: UIButton!
	@IBOutlet var footerLabel: UILabel!

	weak var account: Account?
	weak var delegate: AddAccountDismissDelegate?

	override func viewDidLoad() {
		super.viewDidLoad()
		setupFooter()
		activityIndicator.isHidden = true
		usernameTextField.delegate = self
		passwordTextField.delegate = self

		if let account = account, let credentials = try? account.retrieveCredentials(type: .newsBlurBasic) {
			actionButton.setTitle(Localizations.labelTextUpdateCredentials, for: .normal)
			actionButton.isEnabled = true
			usernameTextField.text = credentials.username
			passwordTextField.text = credentials.secret
		} else {
			actionButton.setTitle(Localizations.labelTextAddAccount, for: .normal)
		}

		NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: UITextField.textDidChangeNotification, object: usernameTextField)
		NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: UITextField.textDidChangeNotification, object: passwordTextField)

		tableView.register(ImageHeaderView.self, forHeaderFooterViewReuseIdentifier: "SectionHeader")
	}

	private func setupFooter() {
		footerLabel.text = Localizations.labelTextSignInToYourNewsblurAccountAndSyncYourFeedsAcrossYourDevicesYourUsernameAndPasswordWillBeEncryptedAndStoredInKeychainDontHaveANewsblurAccount
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return section == 0 ? ImageHeaderView.rowHeight : super.tableView(tableView, heightForHeaderInSection: section)
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if section == 0 {
			let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader") as! ImageHeaderView
			headerView.imageView.image = Assets.accountImage(.newsBlur)
			return headerView
		} else {
			return super.tableView(tableView, viewForHeaderInSection: section)
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

		guard let username = usernameTextField.text else {
			showError(Localizations.labelTextUsernameRequired)
			return
		}

		// When you fill in the email address via auto-complete it adds extra whitespace
		let trimmedUsername = username.trimmingCharacters(in: .whitespaces)

		guard account != nil || !AccountManager.shared.duplicateServiceAccount(type: .newsBlur, username: trimmedUsername) else {
			showError(Localizations.labelTextThereIsAlreadyANewsblurAccountWithThatUsernameCreated)
			return
		}

		let password = passwordTextField.text ?? ""

		Task { @MainActor in
			startAnimatingActivityIndicator()
			disableNavigation()

			@MainActor func stopAnimation() {
				stopAnimatingActivityIndicator()
				enableNavigation()
			}
			let basicCredentials = Credentials(type: .newsBlurBasic, username: trimmedUsername, secret: password)

			do {
				let sessionCredentials = try await Account.validateCredentials(type: .newsBlur, credentials: basicCredentials)
				stopAnimation()

				if let sessionCredentials {
					if account == nil {
						account = AccountManager.shared.createAccount(type: .newsBlur)
					}

					try? account?.removeCredentials(type: .newsBlurBasic)
					try? account?.removeCredentials(type: .newsBlurSessionID)
					do {
						try account?.storeCredentials(basicCredentials)
						try account?.storeCredentials(sessionCredentials)

						do {
							try await account?.refreshAll()
						} catch {
							presentError(error)
						}

						dismiss(animated: true, completion: nil)
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

	@IBAction func signUpWithProvider(_ sender: Any) {
		let url = URL(string: "https://newsblur.com")!
		let safari = SFSafariViewController(url: url)
		safari.modalPresentationStyle = .currentContext
		self.present(safari, animated: true, completion: nil)
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

extension NewsBlurAccountViewController: UITextFieldDelegate {

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}

}
