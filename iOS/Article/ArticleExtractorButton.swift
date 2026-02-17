//
//  ArticleExtractorButton.swift
//  NetNewsWire-iOS
//
//  Created by Maurice Parker on 9/24/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import UIKit
import Localizations

enum ArticleExtractorButtonState {
	case error
	case animated
	case on
	case off
}

final class ArticleExtractorButton: UIButton {

	private var animatedLayer: CALayer?

	var buttonState: ArticleExtractorButtonState = .off {
		didSet {
			if buttonState != oldValue {
				switch buttonState {
				case .error:
					stripAnimatedSublayer()
					setImage(Assets.Images.articleExtractorError, for: .normal)
				case .animated:
					setImage(nil, for: .normal)
					setNeedsLayout()
				case .on:
					stripAnimatedSublayer()
					setImage(Assets.Images.articleExtractorOn, for: .normal)
				case .off:
					stripAnimatedSublayer()
					setImage(Assets.Images.articleExtractorOff, for: .normal)
				}
			}
		}
	}

	override var accessibilityLabel: String? {
		get {
			switch buttonState {
			case .error:
				return Localizations.labelTextErrorReaderView
			case .animated:
				return Localizations.labelTextProcessingReaderView
			case .on:
				return Localizations.labelTextSelectedReaderView
			case .off:
				return Localizations.labelTextReaderView
			}
		}
		set {
			super.accessibilityLabel = newValue
		}
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		guard case .animated = buttonState else {
			return
		}
		stripAnimatedSublayer()
		addAnimatedSublayer(to: layer)
	}

	private func stripAnimatedSublayer() {
		animatedLayer?.removeFromSuperlayer()
	}

	private func addAnimatedSublayer(to hostedLayer: CALayer) {
		let image1 = Assets.Images.articleExtractorOffTinted.cgImage!
		let image2 = Assets.Images.articleExtractorOnTinted.cgImage!
		let images = [image1, image2, image1]

		animatedLayer = CALayer()
		let imageSize = Assets.Images.articleExtractorOff.size
		animatedLayer!.bounds = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
		animatedLayer!.position = CGPoint(x: bounds.midX, y: bounds.midY)

		hostedLayer.addSublayer(animatedLayer!)

		let animation = CAKeyframeAnimation(keyPath: "contents")
		animation.calculationMode = CAAnimationCalculationMode.linear
		animation.keyTimes = [0, 0.5, 1]
		animation.duration = 2
		animation.values = images as [Any]
		animation.repeatCount = HUGE

		animatedLayer!.add(animation, forKey: "contents")
	}

}
