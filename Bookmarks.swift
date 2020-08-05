//
//  Bookmarks.swift
//

import Cocoa

class bookmarks {
	// Class variables
	var bookmarkURL = [URL: Data]()
	
	// Load previous bookmarks
	func load() {
		let path = getPath()
		bookmarkURL = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [URL: Data] ?? [URL: Data]()
		for bookmark in bookmarkURL {
			restore(bookmark)
		}
	}
	
	// Add a folder to bookmarks
	func store(url: URL) {
		let data = try! url.bookmarkData(options: NSURL.BookmarkCreationOptions.withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
		let path = getPath()
		bookmarkURL[url] = data
		NSKeyedArchiver.archiveRootObject(bookmarkURL, toFile: path)
	}
	
	// Get bookmark path
	func getPath() -> String {
		var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
		url = url.appendingPathComponent("Bookmarks.dict")
		return url.path
	}
	
	// Remove bookmark
	func update() {
		try! FileManager.default.removeItem(at: URL(fileURLWithPath: getPath()))
		for folders in folderPairs {
			// Store folders in bookmarks
			store(url: URL(fileURLWithPath: folders[0]))
			store(url: URL(fileURLWithPath: folders[1]))
		}
	}
	
	// Restore saved bookmark
	func restore(_ bookmark: (key: URL, value: Data)) {
		let restoredUrl: URL?
		var isStale = false
		do {
			restoredUrl = try URL.init(resolvingBookmarkData: bookmark.value, options: NSURL.BookmarkResolutionOptions.withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
		}
		catch { restoredUrl = nil }
	}
}

