//
//  UndoAvailableAlertController.swift
//  NetNewsWire
//
//  Created by Phil Viso on 9/29/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation
import UIKit
import Localizations

protocol MarkAsReadAlertControllerSourceType {}
extension CGRect: MarkAsReadAlertControllerSourceType {}
extension UIView: MarkAsReadAlertControllerSourceType {}
extension UIBarButtonItem: MarkAsReadAlertControllerSourceType {}

@MainActor struct MarkAsReadAlertController {

	static func confirm<T>(_ controller: UIViewController?,
	                       coordinator: SceneCoordinator?,
	                       confirmTitle: String,
	                       sourceType: T,
	                       cancelCompletion: (() -> Void)? = nil,
	                       completion: @escaping () -> Void) where T: MarkAsReadAlertControllerSourceType {

		guard let controller, let coordinator else {
			completion()
			return
		}

		if AppDefaults.shared.confirmMarkAllAsRead {
			let alertController = MarkAsReadAlertController.alert(coordinator: coordinator, confirmTitle: confirmTitle, cancelCompletion: cancelCompletion, sourceType: sourceType) { _ in
				completion()
			}
			controller.present(alertController, animated: true)
		} else {
			completion()
		}
	}

	private static func alert<T>(coordinator: SceneCoordinator,
	                             confirmTitle: String,
	                             cancelCompletion: (() -> Void)?,
	                             sourceType: T,
	                             completion: @escaping (UIAlertAction) -> Void) -> UIAlertController where T: MarkAsReadAlertControllerSourceType {

		let title = Localizations.labelTextMarkAsRead2
		let message = Localizations.labelTextYouCanTurnThisConfirmationOffInSettings
		let cancelTitle = Localizations.labelTextCancel
		let settingsTitle = Localizations.labelTextOpenSettings

		let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
		let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
			cancelCompletion?()
		}
		let settingsAction = UIAlertAction(title: settingsTitle, style: .default) { _ in
			Task { @MainActor in
				coordinator.showSettings(scrollToArticlesSection: true)
			}
		}
		let markAction = UIAlertAction(title: confirmTitle, style: .default, handler: completion)

		alertController.addAction(markAction)
		alertController.addAction(settingsAction)
		alertController.addAction(cancelAction)

		if let barButtonItem = sourceType as? UIBarButtonItem {
			alertController.popoverPresentationController?.barButtonItem = barButtonItem
		}

		if let rect = sourceType as? CGRect {
			alertController.popoverPresentationController?.sourceRect = rect
		}

		if let view = sourceType as? UIView {
			alertController.popoverPresentationController?.sourceView = view
		}

		return alertController
	}

}
