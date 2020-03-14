//
//  NewsBlurAccountDelegate+Private.swift
//  Mostly adapted from FeedbinAccountDelegate.swift
//  Account
//
//  Created by Anh Quang Do on 2020-03-14.
//  Copyright (c) 2020 Ranchero Software, LLC. All rights reserved.
//

import Articles
import RSCore
import RSDatabase
import RSParser
import RSWeb
import SyncDatabase
import os.log

extension NewsBlurAccountDelegate {
	func refreshFeeds(for account: Account, completion: @escaping (Result<Void, Error>) -> Void) {
		os_log(.debug, log: log, "Refreshing feeds...")

		caller.retrieveFeeds { result in
			switch result {
			case .success((let feeds, let folders)):
				BatchUpdate.shared.perform {
					self.syncFolders(account, folders)
					self.syncFeeds(account, feeds)
					self.syncFeedFolderRelationship(account, folders)
				}

				self.refreshProgress.completeTask()
				completion(.success(()))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}

	func syncFolders(_ account: Account, _ folders: [NewsBlurFolder]?) {
		guard let folders = folders else { return }
		assert(Thread.isMainThread)

		os_log(.debug, log: log, "Syncing folders with %ld folders.", folders.count)

		let folderNames = folders.map { $0.name }

		// Delete any folders not at NewsBlur
		if let folders = account.folders {
			folders.forEach { folder in
				if !folderNames.contains(folder.name ?? "") {
					for feed in folder.topLevelWebFeeds {
						account.addWebFeed(feed)
						clearFolderRelationship(for: feed, withFolderName: folder.name ?? "")
					}
					account.removeFolder(folder)
				}
			}
		}

		let accountFolderNames: [String] =  {
			if let folders = account.folders {
				return folders.map { $0.name ?? "" }
			} else {
				return [String]()
			}
		}()

		// Make any folders NewsBlur has, but we don't
		folderNames.forEach { folderName in
			if !accountFolderNames.contains(folderName) {
				_ = account.ensureFolder(with: folderName)
			}
		}
	}

	func syncFeeds(_ account: Account, _ feeds: [NewsBlurFeed]?) {
		guard let feeds = feeds else { return }
		assert(Thread.isMainThread)

		os_log(.debug, log: log, "Syncing feeds with %ld feeds.", feeds.count)

		let subFeedIds = feeds.map { String($0.feedID) }

		// Remove any feeds that are no longer in the subscriptions
		if let folders = account.folders {
			for folder in folders {
				for feed in folder.topLevelWebFeeds {
					if !subFeedIds.contains(feed.webFeedID) {
						folder.removeWebFeed(feed)
					}
				}
			}
		}

		for feed in account.topLevelWebFeeds {
			if !subFeedIds.contains(feed.webFeedID) {
				account.removeWebFeed(feed)
			}
		}

		// Add any feeds we don't have and update any we do
		var feedsToAdd = Set<NewsBlurFeed>()
		feeds.forEach { feed in
			let subFeedId = String(feed.feedID)

			if let webFeed = account.existingWebFeed(withWebFeedID: subFeedId) {
				webFeed.name = feed.name
				// If the name has been changed on the server remove the locally edited name
				webFeed.editedName = nil
				webFeed.homePageURL = feed.homepageURL
				webFeed.subscriptionID = String(feed.feedID)
				webFeed.faviconURL = feed.faviconURL
			}
			else {
				feedsToAdd.insert(feed)
			}
		}

		// Actually add feeds all in one go, so we don’t trigger various rebuilding things that Account does.
		feedsToAdd.forEach { feed in
			let webFeed = account.createWebFeed(with: feed.name, url: feed.feedURL, webFeedID: String(feed.feedID), homePageURL: feed.homepageURL)
			webFeed.subscriptionID = String(feed.feedID)
			account.addWebFeed(webFeed)
		}
	}

	func syncFeedFolderRelationship(_ account: Account, _ folders: [NewsBlurFolder]?) {
		guard let folders = folders else { return }
		assert(Thread.isMainThread)

		os_log(.debug, log: log, "Syncing folders with %ld folders.", folders.count)

		// Set up some structures to make syncing easier
		let relationships = folders.map({ $0.asRelationships }).flatMap { $0 }
		let folderDict = nameToFolderDictionary(with: account.folders)
		let foldersDict = relationships.reduce([String: [NewsBlurFolderRelationship]]()) { (dict, relationship) in
			var feedInFolders = dict
			if var feedInFolder = feedInFolders[relationship.folderName] {
				feedInFolder.append(relationship)
				feedInFolders[relationship.folderName] = feedInFolder
			} else {
				feedInFolders[relationship.folderName] = [relationship]
			}
			return feedInFolders
		}

		// Sync the folders
		for (folderName, folderRelationships) in foldersDict {
			guard let folder = folderDict[folderName] else { return }

			let folderFeedIDs = folderRelationships.map { String($0.feedID) }

			// Move any feeds not in the folder to the account
			for feed in folder.topLevelWebFeeds {
				if !folderFeedIDs.contains(feed.webFeedID) {
					folder.removeWebFeed(feed)
					clearFolderRelationship(for: feed, withFolderName: folder.name ?? "")
					account.addWebFeed(feed)
				}
			}

			// Add any feeds not in the folder
			let folderFeedIds = folder.topLevelWebFeeds.map { $0.webFeedID }

			for relationship in folderRelationships {
				let folderFeedID = String(relationship.feedID)
				if !folderFeedIds.contains(folderFeedID) {
					guard let feed = account.existingWebFeed(withWebFeedID: folderFeedID) else {
						continue
					}
					saveFolderRelationship(for: feed, withFolderName: folderName, id: relationship.folderName)
					folder.addWebFeed(feed)
				}
			}

		}

		let folderFeedIDs = Set(relationships.map { String($0.feedID) })

		// Remove all feeds from the account container that have a tag
		for feed in account.topLevelWebFeeds {
			if folderFeedIDs.contains(feed.webFeedID) {
				account.removeWebFeed(feed)
			}
		}
	}

	func clearFolderRelationship(for feed: WebFeed, withFolderName folderName: String) {
		if var folderRelationship = feed.folderRelationship {
			folderRelationship[folderName] = nil
			feed.folderRelationship = folderRelationship
		}
	}

	func saveFolderRelationship(for feed: WebFeed, withFolderName folderName: String, id: String) {
		if var folderRelationship = feed.folderRelationship {
			folderRelationship[folderName] = id
			feed.folderRelationship = folderRelationship
		} else {
			feed.folderRelationship = [folderName: id]
		}
	}

	func nameToFolderDictionary(with folders: Set<Folder>?) -> [String: Folder] {
		guard let folders = folders else {
			return [String: Folder]()
		}

		var d = [String: Folder]()
		for folder in folders {
			let name = folder.name ?? ""
			if d[name] == nil {
				d[name] = folder
			}
		}
		return d
	}

	func refreshUnreadStories(for account: Account, hashes: [NewsBlurStoryHash]?, updateFetchDate: Date?, completion: @escaping (Result<Void, Error>) -> Void) {
		guard let hashes = hashes, !hashes.isEmpty else {
			if let lastArticleFetch = updateFetchDate {
				self.accountMetadata?.lastArticleFetchStartTime = lastArticleFetch
				self.accountMetadata?.lastArticleFetchEndTime = Date()
			}
			completion(.success(()))
			return
		}

		let numberOfStories = min(hashes.count, 100) // api limit
		let hashesToFetch = Array(hashes[..<numberOfStories])

		caller.retrieveStories(hashes: hashesToFetch) { result in
			switch result {
			case .success(let stories):
				self.processStories(account: account, stories: stories) { error in
					self.refreshProgress.completeTask()

					if let error = error {
						completion(.failure(error))
						return
					}

					self.refreshUnreadStories(for: account, hashes: Array(hashes[numberOfStories...]), updateFetchDate: updateFetchDate) { result in
						os_log(.debug, log: self.log, "Done refreshing stories.")
						switch result {
						case .success:
							completion(.success(()))
						case .failure(let error):
							completion(.failure(error))
						}
					}
				}
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}

	func mapStoriesToParsedItems(stories: [NewsBlurStory]?) -> Set<ParsedItem> {
		guard let stories = stories else { return Set<ParsedItem>() }

		let parsedItems: [ParsedItem] = stories.map { story in
			let author = Set([ParsedAuthor(name: story.authorName, url: nil, avatarURL: nil, emailAddress: nil)])
			return ParsedItem(syncServiceID: story.storyID, uniqueID: String(story.storyID), feedURL: String(story.feedID), url: story.url, externalURL: nil, title: story.title, contentHTML: story.contentHTML, contentText: nil, summary: nil, imageURL: nil, bannerImageURL: nil, datePublished: story.datePublished, dateModified: nil, authors: author, tags: nil, attachments: nil)
		}

		return Set(parsedItems)
	}

	func sendStoryStatuses(_ statuses: [SyncStatus],
								   throttle: Bool,
								   apiCall: ([String], @escaping (Result<Void, Error>) -> Void) -> Void,
								   completion: @escaping (Result<Void, Error>) -> Void) {
		guard !statuses.isEmpty else {
			completion(.success(()))
			return
		}

		let group = DispatchGroup()
		var errorOccurred = false

		let storyHashes = statuses.compactMap { $0.articleID }
		let storyHashGroups = storyHashes.chunked(into: throttle ? 1 : 5) // api limit
		for storyHashGroup in storyHashGroups {
			group.enter()
			apiCall(storyHashGroup) { result in
				switch result {
				case .success:
					self.database.deleteSelectedForProcessing(storyHashGroup.map { String($0) } )
					group.leave()
				case .failure(let error):
					errorOccurred = true
					os_log(.error, log: self.log, "Story status sync call failed: %@.", error.localizedDescription)
					self.database.resetSelectedForProcessing(storyHashGroup.map { String($0) } )
					group.leave()
				}
			}
		}

		group.notify(queue: DispatchQueue.main) {
			if errorOccurred {
				completion(.failure(NewsBlurError.unknown))
			} else {
				completion(.success(()))
			}
		}
	}

	func syncStoryReadState(account: Account, hashes: [NewsBlurStoryHash]?) {
		guard let hashes = hashes else { return }

		database.selectPendingReadStatusArticleIDs() { result in
			func process(_ pendingStoryHashes: Set<String>) {

				let newsBlurUnreadStoryHashes = Set(hashes.map { $0.hash } )
				let updatableNewsBlurUnreadStoryHashes = newsBlurUnreadStoryHashes.subtracting(pendingStoryHashes)

				account.fetchUnreadArticleIDs { articleIDsResult in
					guard let currentUnreadArticleIDs = try? articleIDsResult.get() else {
						return
					}

					// Mark articles as unread
					let deltaUnreadArticleIDs = updatableNewsBlurUnreadStoryHashes.subtracting(currentUnreadArticleIDs)
					account.markAsUnread(deltaUnreadArticleIDs)

					// Mark articles as read
					let deltaReadArticleIDs = currentUnreadArticleIDs.subtracting(updatableNewsBlurUnreadStoryHashes)
					account.markAsRead(deltaReadArticleIDs)
				}
			}

			switch result {
			case .success(let pendingArticleIDs):
				process(pendingArticleIDs)
			case .failure(let error):
				os_log(.error, log: self.log, "Sync Story Read Status failed: %@.", error.localizedDescription)
			}
		}
	}

	func syncStoryStarredState(account: Account, hashes: [NewsBlurStoryHash]?) {
		guard let hashes = hashes else { return }

		database.selectPendingStarredStatusArticleIDs() { result in
			func process(_ pendingStoryHashes: Set<String>) {

				let newsBlurStarredStoryHashes = Set(hashes.map { $0.hash } )
				let updatableNewsBlurUnreadStoryHashes = newsBlurStarredStoryHashes.subtracting(pendingStoryHashes)

				account.fetchStarredArticleIDs { articleIDsResult in
					guard let currentStarredArticleIDs = try? articleIDsResult.get() else {
						return
					}

					// Mark articles as starred
					let deltaStarredArticleIDs = updatableNewsBlurUnreadStoryHashes.subtracting(currentStarredArticleIDs)
					account.markAsStarred(deltaStarredArticleIDs)

					// Mark articles as unstarred
					let deltaUnstarredArticleIDs = currentStarredArticleIDs.subtracting(updatableNewsBlurUnreadStoryHashes)
					account.markAsUnstarred(deltaUnstarredArticleIDs)
				}
			}

			switch result {
			case .success(let pendingArticleIDs):
				process(pendingArticleIDs)
			case .failure(let error):
				os_log(.error, log: self.log, "Sync Story Starred Status failed: %@.", error.localizedDescription)
			}
		}
	}
}
