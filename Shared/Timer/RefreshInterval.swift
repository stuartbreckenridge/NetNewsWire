//
//  RefreshInterval.swift
//  NetNewsWire-iOS
//
//  Created by Maurice Parker on 4/23/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation
import Localizations

enum RefreshInterval: Int, CaseIterable, Identifiable {
	case manually = 1
	case every10Minutes = 2
	case every30Minutes = 3
	case everyHour = 4
	case every2Hours = 5
	case every4Hours = 6
	case every8Hours = 7

	func inSeconds() -> TimeInterval {
		switch self {
		case .manually:
			return 0
		case .every10Minutes:
			return 10 * 60
		case .every30Minutes:
			return 30 * 60
		case .everyHour:
			return 60 * 60
		case .every2Hours:
			return 2 * 60 * 60
		case .every4Hours:
			return 4 * 60 * 60
		case .every8Hours:
			return 8 * 60 * 60
		}
	}

	var id: String { description() }

	func description() -> String {
		switch self {
		case .manually:
			return Localizations.labelTextManually
		case .every10Minutes:
			return Localizations.labelTextEvery10Minutes
		case .every30Minutes:
			return Localizations.labelTextEvery30Minutes
		case .everyHour:
			return Localizations.labelTextEveryHour
		case .every2Hours:
			return Localizations.labelTextEvery2Hours
		case .every4Hours:
			return Localizations.labelTextEvery4Hours
		case .every8Hours:
			return Localizations.labelTextEvery8Hours
		}
	}

}
