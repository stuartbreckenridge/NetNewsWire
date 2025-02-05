//
//  ColorHash.swift
//  ColorHash
//
//  Created by Atsushi Nagase on 11/25/15.
//  Copyright © 2015 LittleApps Inc. All rights reserved.
//
// Original Project: https://github.com/ngs/color-hash.swift

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(OSX)
import AppKit
#endif

public final class ColorHash {

	public static let defaultSaturation = [CGFloat(0.35), CGFloat(0.5), CGFloat(0.65)]
	public static let defaultBrightness = [CGFloat(0.5), CGFloat(0.65), CGFloat(0.80)]

	let seed = CGFloat(131.0)
	let seed2 = CGFloat(137.0)
	let maxSafeInteger = 9007199254740991.0 / CGFloat(137.0)
	let full = CGFloat(360.0)

	public private(set) var str: String
	public private(set) var brightness: [CGFloat]
	public private(set) var saturation: [CGFloat]

	public init(_ str: String, _ saturation: [CGFloat] = defaultSaturation, _ brightness: [CGFloat] = defaultBrightness) {
		self.str = str
		self.saturation = saturation
		self.brightness = brightness
	}

	public var bkdrHash: CGFloat {
		var hash = CGFloat(0)
		for char in "\(str)x" {
			if let scl = String(char).unicodeScalars.first?.value {
				if hash > maxSafeInteger {
					hash /= seed2
				}
				hash = hash * seed + CGFloat(scl)
			}
		}
		return hash
	}

	public var HSB: (CGFloat, CGFloat, CGFloat) {
		var hash = CGFloat(bkdrHash)
		let h = hash.truncatingRemainder(dividingBy: (full - 1.0)) / full
		hash /= full
		let s = saturation[Int((full * hash).truncatingRemainder(dividingBy: CGFloat(saturation.count)))]
		hash /= CGFloat(saturation.count)
		let b = brightness[Int((full * hash).truncatingRemainder(dividingBy: CGFloat(brightness.count)))]
		return (h, s, b)
	}

	#if os(iOS) || os(tvOS) || os(watchOS)
	public var color: UIColor {
		let (h, s, b) = HSB
		return UIColor(hue: h, saturation: s, brightness: b, alpha: 1.0)
	}
	#elseif os(OSX)
	public var color: NSColor {
		let (h, s, b) = HSB
		return NSColor(hue: h, saturation: s, brightness: b, alpha: 1.0)
	}
	#endif

}
