//
//  Sync.swift
//

import Cocoa

class sync {
	// Select directories for syncing
	func select() {
		// Setup dialog
		let dialog = NSOpenPanel();
		dialog.showsResizeIndicator = true;
		dialog.showsHiddenFiles = false;
		dialog.allowsMultipleSelection = false;
		dialog.canChooseDirectories = true;
		dialog.canChooseFiles = false;

		// Select folders
		var folders = ["",""]
		for f in 0...1 {
			if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
				// Path of file
				let result = dialog.url
				
				// Make sure path isn't empty
				if (result != nil) {
					let path: String = result!.path
					folders[f] = path
					// Add folder pair to global array
					if f == 1 {
						folderPairs.append(folders)
						UserDefaults.standard.set(folderPairs, forKey: "keyFoldersToSync")
						bookmarkManager.store(url: URL(fileURLWithPath: folders[0]))
						bookmarkManager.store(url: URL(fileURLWithPath: folders[1]))
					}
				}
			}
		}
	}
	
	
	//
	func sync(_ directory: [String]) {
		let filesInDirectoryA = try! FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: directory[0]), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
		let filesInDirectoryB = try! FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: directory[1]), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
		var fileList = [URL]()
		var filesToIgnore = [URL]()
		var subdirectoryList = [URL]()
		
		// Iterate through directory A
		processDirectory(filesInDirectoryA, filesInDirectoryB, &fileList, &subdirectoryList, &filesToIgnore, secondIteration: false)
		processDirectory(filesInDirectoryB, fileList, &fileList, &subdirectoryList, &filesToIgnore, secondIteration: true)
		
		// Process tasks
		processTasks(filesInDirectoryA, filesInDirectoryB, &fileList, directory, isSubdirectory: false)
		processTasks(filesInDirectoryA, filesInDirectoryB, &subdirectoryList, directory, isSubdirectory: true)
		
	}
	
	// Process a directory pair
	func processDirectory(_ listA: [URL], _ listB: [URL], _ itemList: inout [URL], _ subdirectoryList: inout [URL], _ ignoreList: inout [URL], secondIteration: Bool) {
		for itemA in listA {
			if let b = listB.firstIndex(where: {$0.lastPathComponent == itemA.lastPathComponent}) {
				// A matching file has been found, check which is newer
				let itemB = listB[b]
				let comparison = compareDates(itemA, itemB)
				if comparison == .orderedDescending {
					if itemA.hasDirectoryPath {
						if secondIteration {
							if !ignoreList.contains(itemA) {
								subdirectoryList.append(itemA)
							}
						}
						else {
							ignoreList.append(itemB)
							subdirectoryList.append(itemA)
						}
					}
					else {
						if secondIteration {
							itemList.remove(at: b)
						}
						itemList.append(itemA)
					}
				}
				else if comparison == .orderedSame && !secondIteration { ignoreList.append(itemB) }
			}
			else {
				if secondIteration {
					if !ignoreList.contains(itemA) {
						if itemA.hasDirectoryPath {
							subdirectoryList.append(itemA)
						}
						else {
							itemList.append(itemA)
						}
					}
				}
				else {
					if itemA.hasDirectoryPath {
						subdirectoryList.append(itemA)
					}
					else {
						itemList.append(itemA)
					}
				}
			}
		}
	}
	
	// Process tasks
	func processTasks(_ listA: [URL], _ listB: [URL], _ itemList: inout [URL], _ directory: [String], isSubdirectory: Bool) {
		for item in itemList {
			let occurrence = item.hasDirectoryPath ? "/" + item.lastPathComponent + "/" : "/" + item.lastPathComponent
			var directoryOfItem = item.absoluteString.removingPercentEncoding!.replacingOccurrences(of: "file://", with: "")
			directoryOfItem = directoryOfItem.replacingOccurrences(of: occurrence, with: "")
			
			var indexA = 0, indexB = 1, list = listB
			if directoryOfItem == directory[1] {
				indexA = 1
				indexB = 0
				list = listA
			}
			
			let itemA = item.hasDirectoryPath ? directory[indexA] + "/" + item.lastPathComponent + "/" : directory[indexA] + "/" + item.lastPathComponent
			let itemB = directory[indexB] + "/" + item.lastPathComponent
			if list.firstIndex(where: {$0.lastPathComponent == item.lastPathComponent}) != nil {
				// There is a file with the same name in the opposite directory
				if isSubdirectory { sync([itemA, itemB]) }
				else {
					remove(URL(fileURLWithPath: itemB))
					move(URL(fileURLWithPath: itemA), URL(fileURLWithPath: itemB))
				}
			}
			else { move(URL(fileURLWithPath: itemA), URL(fileURLWithPath: itemB)) }
		}
	}
	
	// Compare the modification date of two files or directories
	func compareDates(_ itemA: URL, _ itemB: URL) -> ComparisonResult {
		let modificationDateA = try! itemA.resourceValues(forKeys: [.contentModificationDateKey, .nameKey]).contentModificationDate!
		let modificationDateB = try! itemB.resourceValues(forKeys: [.contentModificationDateKey, .nameKey]).contentModificationDate!
		return modificationDateA.compare(modificationDateB)
	}
	
	// Move files in background
	func move(_ file: URL, _ destination: URL) {
		let dispatchQueue = DispatchQueue(label: "QueueIdentification", qos: .background)
		dispatchQueue.async {
			try! FileManager.default.copyItem(at: file, to: destination)
		}
	}
	
	// Remove file
	func remove(_ file: URL) {
		try! FileManager.default.removeItem(at: file)
	}
}

struct File {
	var index: Int
	var url: URL
}
