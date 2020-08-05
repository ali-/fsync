//
//  AppDelegate.swift
//

import Cocoa

// Global variable
var syncManager = sync()
var bookmarkManager = bookmarks()
var folderPairs = [[String]]()
var statusItem = NSStatusItem()

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	// Application code
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		bookmarkManager.load()
		folderPairs = UserDefaults.standard.object(forKey:"keyFoldersToSync") as? [[String]] ?? [[String]]()
		UserDefaults.standard.set(NSControl.StateValue.off, forKey: "keyHasSuppressedWarning")
		updateMenu()
	}
	
	// Run before quitting application
	func applicationWillTerminate(_ aNotification: Notification) {
		//
	}

	// Refresh menu bar
	func updateMenu() {
		statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
		statusItem.button?.image = NSImage(named: NSImage.folderName)
		statusItem.button?.image?.size = NSSize(width: 20, height: 20)
		statusItem.button?.font = NSFont.systemFont(ofSize: 22)
		statusItem.length = 32
		
		// Add menu items to status bar
		let menu = NSMenu()
		for item in getMenuItems() {
			menu.addItem(item)
		}
		statusItem.menu = menu
	}

	// Create menu items
	func getMenuItems() -> [NSMenuItem] {
		var menuItems = [NSMenuItem]()
		let itemAbout = NSMenuItem(title: "About", action: #selector(actionAbout), keyEquivalent: "")
		let itemSelectFolders = NSMenuItem(title: "Select Folders", action: #selector(actionSelectDirectories(_:)), keyEquivalent: "")
		let itemQuit = NSMenuItem(title: "Quit", action: #selector(actionQuit), keyEquivalent: "")
		
		// Append items to NSMenuItem array
		menuItems.append(itemSelectFolders)
		menuItems.append(NSMenuItem.separator())
		for f in 0..<folderPairs.count {
			let folderA = folderPairs[f][0].split(separator: "/")
			let folderB = folderPairs[f][1].split(separator: "/")
			let itemFolder = NSMenuItem(title: "\(folderA[folderA.count-1]) & \(folderB[folderB.count-1])", action: #selector(actionData), keyEquivalent: "")
			itemFolder.image = NSImage(named: NSImage.folderName)
			itemFolder.image?.size = NSSize(width: 16, height: 16)
			itemFolder.representedObject = folderPairs[f]
			let itemSubRemove = NSMenuItem(title: "Remove", action: #selector(actionRemove), keyEquivalent: "")
			itemSubRemove.representedObject = f
			let sm = NSMenu()
			sm.addItem(itemSubRemove)
			itemFolder.submenu = sm
			menuItems.append(itemFolder)
		}
		menuItems.append(NSMenuItem.separator())
		menuItems.append(itemAbout)
		menuItems.append(itemQuit)
		
		// Return menu
		return menuItems
	}
	
	// Directory select action
	@objc func actionAbout(_ sender: Any?) {
		let alert = NSAlert()
		let info = "Version 0.1"
		alert.messageText = "About"
		alert.icon = nil
		alert.informativeText =	(info)
		alert.alertStyle = .informational
		alert.addButton(withTitle: "Visit Website")
		alert.addButton(withTitle: "Cancel")
		if alert.runModal() == .alertFirstButtonReturn {
			NSWorkspace.shared.open(URL(string: "https://ali.af/projects/fsync.html")!)
		}
	}
	
	// Directory select action
	@objc func actionSelectDirectories(_ sender: Any?) {
		syncManager.select()
		updateMenu()
	}

	// Remove directory pair
	@objc func actionRemove(_ sender: NSMenuItem) {
		let index = sender.representedObject as! Int
		folderPairs.remove(at: index)
		UserDefaults.standard.set(folderPairs, forKey: "keyFoldersToSync")
		bookmarkManager.update()
		updateMenu()
	}

	// Sync directory pair
	@objc func actionData(_ sender: NSMenuItem) {
		let directories = sender.representedObject as! [String]
		let alertState = UserDefaults.standard.object(forKey:"keyHasSuppressedWarning") as! NSControl.StateValue
		if alertState == NSControl.StateValue.off {
			let alert = NSAlert()
			alert.messageText = "Manual Sync"
			alert.informativeText = "Would you like to sync the directories \"\(directories[0].split(separator: "/").last!)\" and \"\(directories[1].split(separator: "/").last!)\" now?"
			alert.alertStyle = .warning
			alert.addButton(withTitle: "OK")
			alert.addButton(withTitle: "Cancel")
			alert.showsSuppressionButton = true
			if alert.runModal() == .alertFirstButtonReturn {
				syncManager.sync(directories)
				UserDefaults.standard.set(alert.suppressionButton!.state, forKey: "keyHasSuppressedWarning")
			}
		}
		else { syncManager.sync(directories) }
	}

	// Exit program
	@objc func actionQuit(_ sender: Any?) {
		NSApplication.shared.terminate(self)
	}
	
}
