//
//  ArticleTextSize.swift
//  NetNewsWire
//
//  Created by Maurice Parker on 11/3/20.
//  Copyright © 2020 Ranchero Software. All rights reserved.
//

import Foundation
import Localizations

enum ArticleTextSize: Int, CaseIterable, Identifiable {
	case small = 1
	case medium = 2
	case large = 3
	case xlarge = 4
	case xxlarge = 5

	var id: String { description() }

	var cssClass: String {
		switch self {
		case .small:
			return "smallText"
		case .medium:
			return "mediumText"
		case .large:
			return "largeText"
		case .xlarge:
			return "xLargeText"
		case .xxlarge:
			return "xxLargeText"
		}
	}

	func description() -> String {
		switch self {
		case .small:
			return Localizations.labelTextSmall
		case .medium:
			return Localizations.labelTextMedium
		case .large:
			return Localizations.labelTextLarge
		case .xlarge:
			return Localizations.labelTextExtraLarge
		case .xxlarge:
			return Localizations.labelTextExtraExtraLarge
		}
	}

}
