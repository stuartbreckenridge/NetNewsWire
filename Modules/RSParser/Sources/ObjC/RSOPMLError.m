//
//  RSOPMLError.m
//  RSParser
//
//  Created by Brent Simmons on 2/28/16.
//  Copyright © 2016 Ranchero Software, LLC. All rights reserved.
//

#import "RSOPMLError.h"

NSString *RSOPMLErrorDomain = @"com.ranchero.OPML";

static NSString *RSSharedLocalizedString(NSString *key, NSString *fallback) {
	NSBundle *localizationsBundle = nil;

	for (NSBundle *bundle in [NSBundle allBundles]) {
		if ([bundle.bundlePath hasSuffix:@"Localizations_Localizations.bundle"] || [bundle.bundleIdentifier hasSuffix:@"Localizations.Localizations"]) {
			localizationsBundle = bundle;
			break;
		}
	}

	if (localizationsBundle == nil) {
		NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Localizations_Localizations" ofType:@"bundle"];
		if (bundlePath != nil) {
			localizationsBundle = [NSBundle bundleWithPath:bundlePath];
		}
	}

	if (localizationsBundle == nil) {
		localizationsBundle = [NSBundle mainBundle];
	}

	return [localizationsBundle localizedStringForKey:key value:fallback table:nil];
}

NSError *RSOPMLWrongFormatError(NSString *fileName) {

	NSString *localizedDescriptionFormatString = RSSharedLocalizedString(@"label.text.the-file-cant-be-parsed-because-its-not-an-opml-file", @"The file ‘%@’ can’t be parsed because it’s not an OPML file.");
	NSString *localizedDescription = [NSString stringWithFormat:localizedDescriptionFormatString, fileName];

	NSString *localizedFailureString = RSSharedLocalizedString(@"label.text.the-file-is-not-an-opml-file", @"The file is not an OPML file.");
	NSDictionary *userInfo = @{NSLocalizedDescriptionKey: localizedDescription, NSLocalizedFailureReasonErrorKey: localizedFailureString};

	return [[NSError alloc] initWithDomain:RSOPMLErrorDomain code:RSOPMLErrorCodeDataIsWrongFormat userInfo:userInfo];
}
