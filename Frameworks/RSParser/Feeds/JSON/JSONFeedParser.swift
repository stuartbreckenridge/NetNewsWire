//
//  JSONFeedParser.swift
//  RSParser
//
//  Created by Brent Simmons on 6/25/17.
//  Copyright © 2017 Ranchero Software, LLC. All rights reserved.
//

import Foundation

// See https://jsonfeed.org/version/1

public struct JSONFeedParser {

	public static func parse(parserData: ParserData) throws -> ParsedFeed? {

		do {
			let parsedObject = try JSONSerialization.jsonObject(with: parserData.data)

			guard let version = parsedObject["version"] as? String, version.hasPrefix("https://jsonfeed.org/version/") else {
				throw FeedParserError(.jsonFeedVersionNotFound)
			}
			guard let itemsArray = parsedObject["items"] as? JSONArray else {
				throw FeedParserError(.jsonFeedItemsNotFound)
			}
			guard let title = parsedObject["title"] as? String else {
				throw FeedParserError(.jsonFeedTitleNotFound)
			}

			let homePageURL = parsedObject["home_page_url"] as? String
			let feedURL = parsedObject["feed_url"] ?? parserData.url
			let feedDescription = parsedObject["description"] as? String
			let nextURL = parsedObject["next_url"] as? String
			let iconURL = parsedObject["icon_url"] as? String
			let faviconURL = parsedObject["favicon_url"] as? String
			let authors = parseAuthors(parsedObject)
			let expired = parsedObject["expired"] as? Bool ?? false
			let hubs = parseHubs(parsedObject)

			let items = parseItems(itemsArray)

			return ParsedFeed(type: .jsonFeed, title: title, homePageURL: homePageURL, feedURL: feedURL, feedDescription: feedDescription, nextURL: nextURL, iconURL: iconURL, faviconURL: faviconURL, authors: authors, expired: expired, hubs: hubs, items: items)

		}
		catch { throw error }
	}
}

private extension JSONFeedParser {

	func parseAuthors(_ dictionary: JSONDictionary) -> [ParsedAuthor]? {

		guard let authorDictionary = dictionary["author"] as? JSONDictionary else {
			return nil
		}

		let name = authorDictionary["name"]
		let url = authorDictionary["url"]
		let avatar = authorDictionary["avatar"]
		if name == nil && url == nil && avatar == nil {
			return nil
		}
		let parsedAuthor = ParsedAuthor(name: name, url: url, avatarURL: avatar, emailAddress: nil)
		return [parsedAuthor]
	}

	func parseHubs(_ dictionary: JSONDictionary) -> [ParsedHub]? {

		guard let hubsArray = dictionary["hubs"] as? JSONArray else {
			return nil
		}

		let hubs = hubsArray.flatMap { (oneHubDictionary) -> ParsedHub? in
			guard let oneHubURL = oneHubDictionary["url"], let oneHubType = oneHubDictionary["type"] else {
				return nil
			}
			return ParsedHub(type: oneHubType, url: oneHubURL)
		}
		return hubs.isEmpty ? nil : hubs
	}

	func parseItems(_ itemsArray: JSONArray) -> [ParsedItem] {

		return itemsArray.flatMap { (oneItemDictionary) -> ParsedItem? in
			return parseItem(oneItemDictionary)
		}
	}

	func parseItem(_ itemDictionary: JSONDictionary) -> ParsedItem? {

		guard let uniqueID = parseUniqueID(itemDictionary) else {
			return nil
		}

		let contentHTML = itemDictionary["content_html"] as? String
		let contentText = itemDictionary["content_text"] as? String
		if contentHTML == nil && contentText == nil {
			return nil
		}

		let url = itemDictionary["url"] as? String
		let externalURL = itemDictionary["external_url"] as? String
		let title = itemDictionary["title"] as? String
		let summary = itemDictionary["summary"] as? String
		let imageURL = itemDictionary["image"] as? String
		let bannerImageURL = itemDictionary["banner_image"] as? String

		let datePublished = parseDate(itemDictionary["date_published"])
		let dateModified = parseDate(itemDictionary["date_modified"])

		let authors = parseAuthors(itemDictionary)
		let tags = itemDictionary["tags"] as? [String]
		let attachments = parseAttachments(itemDictionary)

		return ParsedItem(uniqueID: uniqueID, url: url, externalURL: externalURL, title: title, contentHTML: contentHTML, contentText: contentText, summary: summary, imageURL: imageURL, bannerImageURL: bannerImageURL, datePublished: datePublished, dateModified: dateModified, authors: authors, tags: tags, attachments: attachments)
	}

	func parseUniqueID(_ itemDictionary: JSONDictionary) -> String? {

		if let uniqueID = itemDictionary["id"] as? String {
			return uniqueID // Spec says it must be a string
		}
		// Spec also says that if it’s a number, even though that’s incorrect, it should be coerced to a string.
		if let uniqueID = itemDictionary["id"] as? Int {
			return "\(uniqueID)"
		}
		if let uniqueID = itemDictionary["id"] as? Double {
			return "\(uniqueID)"
		}
		return nil
	}

	func parseDate(_ dateString: String?) -> Date? {

		guard let dateString = dateString, !dateString.isEmpty else {
			return nil
		}
		return RSDateWithString(dateString)
	}

	func parseAttachments(_ itemDictionary: JSONDictionary) -> [ParsedAttachment]? {

		guard let attachmentsArray = itemDictionary["attachments"] as? JSONArray else {
			return nil
		}
		return attachmentsArray.flatMap { (oneAttachmentObject) -> ParsedAttachment? in
			return parseAttachment(oneAttachmentObject)
		}
	}

	func parseAttachment(_ attachmentObject: JSONDictionary) -> ParsedAttachment? {

		guard let url = attachmentObject["url"] as? String else {
			return nil
		}
		guard let mimeType = attachmentObject["mime_type"] as? String else {
			return nil
		}

		let title = attachmentObject["title"] as? String
		let sizeInBytes = attachmentObject["size_in_bytes"] as? Int
		let durationInSeconds = attachmentObject["duration_in_seconds"] as? Int
		
		return ParsedAttachment(url: url, mimeType: mimeType, title: title, sizeInBytes: sizeInBytes, durationInSeconds: durationInSeconds)
	}
}
