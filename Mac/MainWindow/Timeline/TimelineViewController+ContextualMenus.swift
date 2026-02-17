//
//  TimelineViewController+ContextualMenus.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 2/9/18.
//  Copyright © 2018 Ranchero Software. All rights reserved.
//

import AppKit
import RSCore
import Articles
import Account
import Localizations

extension TimelineViewController {

	func contextualMenuForClickedRows() -> NSMenu? {

		let row = tableView.clickedRow
		guard row != -1, let article = articles.articleAtRow(row) else {
			return nil
		}

		if selectedArticles.contains(article) {
			// If the clickedRow is part of the selected rows, then do a contextual menu for all the selected rows.
			return menu(for: selectedArticles)
		}
		return menu(for: [article])
	}
}

// MARK: Contextual Menu Actions

extension TimelineViewController {

	@objc func markArticlesReadFromContextualMenu(_ sender: Any?) {
		guard let articles = articles(from: sender) else { return }
		markArticles(articles, read: true)
	}

	@objc func markArticlesUnreadFromContextualMenu(_ sender: Any?) {
		guard let articles = articles(from: sender) else { return }
		markArticles(articles, read: false)
	}

	@objc func markAboveArticlesReadFromContextualMenu(_ sender: Any?) {
		guard let articles = articles(from: sender) else { return }
		markAboveArticlesRead(articles)
	}

	@objc func markBelowArticlesReadFromContextualMenu(_ sender: Any?) {
		guard let articles = articles(from: sender) else { return }
		markBelowArticlesRead(articles)
	}

	@objc func markArticlesStarredFromContextualMenu(_ sender: Any?) {
		guard let articles = articles(from: sender) else { return }
		markArticles(articles, starred: true)
	}

	@objc func markArticlesUnstarredFromContextualMenu(_ sender: Any?) {
		guard let articles = articles(from: sender) else {
			return
		}
		markArticles(articles, starred: false)
	}

	@objc func selectFeedInSidebarFromContextualMenu(_ sender: Any?) {
		guard let menuItem = sender as? NSMenuItem, let feed = menuItem.representedObject as? Feed else {
			return
		}
		delegate?.timelineRequestedFeedSelection(self, feed: feed)
	}

	@objc func markAllInFeedAsRead(_ sender: Any?) {
		guard let menuItem = sender as? NSMenuItem,
			  let feed = menuItem.representedObject as? Feed else {
			return
		}

		guard let unreadArticles = try? feed.fetchUnreadArticles(), !unreadArticles.isEmpty else {
			return
		}
		guard let undoManager, let markReadCommand = MarkStatusCommand(
			initialArticles: Array(unreadArticles),
			markingRead: true,
			undoManager: undoManager
		) else {
			return
		}

		runCommand(markReadCommand)
	}

	@objc func openInBrowserFromContextualMenu(_ sender: Any?) {

		guard let menuItem = sender as? NSMenuItem, let urlString = menuItem.representedObject as? String else {
			return
		}
		Browser.open(urlString, inBackground: false)
	}

	@objc func copyURLFromContextualMenu(_ sender: Any?) {
		guard let menuItem = sender as? NSMenuItem, let urlString = menuItem.representedObject as? String else {
			return
		}
		URLPasteboardWriter.write(urlString: urlString, to: .general)
	}

	@objc func performShareServiceFromContextualMenu(_ sender: Any?) {
		guard let menuItem = sender as? NSMenuItem, let sharingCommandInfo = menuItem.representedObject as? SharingCommandInfo else {
			return
		}
		sharingCommandInfo.perform()
	}
}

private extension TimelineViewController {

	func markArticles(_ articles: [Article], read: Bool) {
		markArticles(articles, statusKey: .read, flag: read)
	}

	func markArticles(_ articles: [Article], starred: Bool) {
		markArticles(articles, statusKey: .starred, flag: starred)
	}

	func markArticles(_ articles: [Article], statusKey: ArticleStatus.Key, flag: Bool) {
		guard let undoManager = undoManager, let markStatusCommand = MarkStatusCommand(initialArticles: articles, statusKey: statusKey, flag: flag, undoManager: undoManager) else {
			return
		}

		runCommand(markStatusCommand)
	}

	func unreadArticles(from articles: [Article]) -> [Article]? {
		let filteredArticles = articles.filter { !$0.status.read }
		return filteredArticles.isEmpty ? nil : filteredArticles
	}

	func readArticles(from articles: [Article]) -> [Article]? {
		let filteredArticles = articles.filter { $0.status.read }
		return filteredArticles.isEmpty ? nil : filteredArticles
	}

	func articles(from sender: Any?) -> [Article]? {
		return (sender as? NSMenuItem)?.representedObject as? [Article]
	}

	func menu(for articles: [Article]) -> NSMenu? {
		let menu = NSMenu(title: "")

		if articles.anyArticleIsUnread() {
			menu.addItem(markReadMenuItem(articles))
		}
		if articles.anyArticleIsReadAndCanMarkUnread() {
			menu.addItem(markUnreadMenuItem(articles))
		}
		if articles.anyArticleIsUnstarred() {
			menu.addItem(markStarredMenuItem(articles))
		}
		if articles.anyArticleIsStarred() {
			menu.addItem(markUnstarredMenuItem(articles))
		}
		if let first = articles.first, self.articles.articlesAbove(article: first).canMarkAllAsRead() {
			menu.addItem(markAboveReadMenuItem(articles))
		}
		if let last = articles.last, self.articles.articlesBelow(article: last).canMarkAllAsRead() {
			menu.addItem(markBelowReadMenuItem(articles))
		}

		menu.addSeparatorIfNeeded()

		if articles.count == 1, let feed = articles.first!.feed {
			if !(representedObjects?.contains(where: { $0 as? Feed == feed }) ?? false) {
				menu.addItem(selectFeedInSidebarMenuItem(feed))
			}
			if let markAllMenuItem = markAllAsReadMenuItem(feed) {
				menu.addItem(markAllMenuItem)
			}
		}

		if articles.count == 1, let link = articles.first!.preferredLink {
			menu.addSeparatorIfNeeded()
			menu.addItem(openInBrowserMenuItem(link))
			menu.addSeparatorIfNeeded()
			menu.addItem(copyArticleURLMenuItem(link))

			if let externalLink = articles.first?.externalLink, externalLink != link {
				menu.addItem(copyExternalURLMenuItem(externalLink))
			}
		}

		menu.addSeparatorIfNeeded()
		let shareButtonMenuItem = NSMenuItem(title: Localizations.labelTextShare2, action: #selector(showShareSheet(_:)), keyEquivalent: "")
		shareButtonMenuItem.target = self
		shareButtonMenuItem.representedObject = articles
		menu.addItem(shareButtonMenuItem)
		shareButtonMenuItem.isEnabled = !articles.isEmpty

		return menu
	}

	@objc func showShareSheet(_ sender: Any?) {
		let articlesToShare: [Article]
		if let menuItem = sender as? NSMenuItem, let representedArticles = menuItem.representedObject as? [Article] {
			articlesToShare = representedArticles
		} else {
			articlesToShare = selectedArticles
		}
		let sortedArticles = articlesToShare.sortedByDate(.orderedAscending)
		let items = sortedArticles.map { ArticlePasteboardWriter(article: $0) }
		let sharingServicePicker = NSSharingServicePicker(items: items)
		sharingServicePicker.delegate = self.sharingServicePickerDelegate

		// Anchor the picker to the first article being shared
		let rowToAnchorTo: Int
		if let firstArticle = articlesToShare.first,
		   let row = articles.firstIndex(where: { $0.articleID == firstArticle.articleID }) {
			rowToAnchorTo = row
		} else {
			rowToAnchorTo = tableView.selectedRow
		}
		let rect = tableView.rect(ofRow: rowToAnchorTo)
		sharingServicePicker.show(relativeTo: rect, of: tableView, preferredEdge: .maxX)
	}

	func markReadMenuItem(_ articles: [Article]) -> NSMenuItem {

		return menuItem(Localizations.labelTextMarkAsRead, #selector(markArticlesReadFromContextualMenu(_:)), articles, image: Assets.Images.swipeMarkRead)
	}

	func markUnreadMenuItem(_ articles: [Article]) -> NSMenuItem {

		return menuItem(Localizations.labelTextMarkAsUnread, #selector(markArticlesUnreadFromContextualMenu(_:)), articles, image: Assets.Images.swipeMarkUnread)
	}

	func markStarredMenuItem(_ articles: [Article]) -> NSMenuItem {

		return menuItem(Localizations.labelTextMarkAsStarred, #selector(markArticlesStarredFromContextualMenu(_:)), articles, image: Assets.Images.swipeMarkStarred)
	}

	func markUnstarredMenuItem(_ articles: [Article]) -> NSMenuItem {

		return menuItem(Localizations.labelTextMarkAsUnstarred, #selector(markArticlesUnstarredFromContextualMenu(_:)), articles, image: Assets.Images.swipeMarkUnstarred)
	}

	func markAboveReadMenuItem(_ articles: [Article]) -> NSMenuItem {
		return menuItem(Localizations.labelTextMarkAboveAsRead, #selector(markAboveArticlesReadFromContextualMenu(_:)), articles, image: Assets.Images.markAboveAsRead)
	}

	func markBelowReadMenuItem(_ articles: [Article]) -> NSMenuItem {
		return menuItem(Localizations.labelTextMarkBelowAsRead, #selector(markBelowArticlesReadFromContextualMenu(_:)), articles, image: Assets.Images.markBelowAsRead)
	}

	func selectFeedInSidebarMenuItem(_ feed: Feed) -> NSMenuItem {
		let localizedMenuText = Localizations.labelTextSelectInSidebar
		let formattedMenuText = NSString.localizedStringWithFormat(localizedMenuText as NSString, feed.nameForDisplay)
		return menuItem(formattedMenuText as String, #selector(selectFeedInSidebarFromContextualMenu(_:)), feed, image: nil)
	}

	func markAllAsReadMenuItem(_ feed: Feed) -> NSMenuItem? {
		guard feed.unreadCount > 0 else {
			return nil
		}

		let localizedMenuText = Localizations.labelTextMarkAllAsReadIn
		let menuText = NSString.localizedStringWithFormat(localizedMenuText as NSString, feed.nameForDisplay) as String

		return menuItem(menuText, #selector(markAllInFeedAsRead(_:)), feed, image: Assets.Images.markAllAsRead)
	}

	func openInBrowserMenuItem(_ urlString: String) -> NSMenuItem {

		return menuItem(Localizations.labelTextOpenInBrowser, #selector(openInBrowserFromContextualMenu(_:)), urlString, image: Assets.Images.openInBrowser)
	}

	func copyArticleURLMenuItem(_ urlString: String) -> NSMenuItem {
		return menuItem(Localizations.labelTextCopyArticleUrl, #selector(copyURLFromContextualMenu(_:)), urlString, image: Assets.Images.copy)
	}

	func copyExternalURLMenuItem(_ urlString: String) -> NSMenuItem {
		return menuItem(Localizations.labelTextCopyExternalUrl, #selector(copyURLFromContextualMenu(_:)), urlString, image: Assets.Images.copy)
	}

	func menuItem(_ title: String, _ action: Selector, _ representedObject: Any, image: RSImage?) -> NSMenuItem {

		let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
		item.representedObject = representedObject
		item.target = self
		if let image {
			item.image = image
		}
		return item
	}
}

private final class SharingCommandInfo {
	let service: NSSharingService
	let items: [Any]

	init(service: NSSharingService, items: [Any]) {
		self.service = service
		self.items = items
	}

	func perform() {
		service.perform(withItems: items)
	}
}
