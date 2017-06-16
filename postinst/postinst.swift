import MobileCoreServices

let workspace = LSApplicationWorkspace.default()!

// MARK: - Helpers

func registerApp(identifier: String, path: URL) {
	// try to get an app with a matching name
	let app = LSApplicationProxy(forIdentifier: identifier)

	// if we got nothing back, we’re not registered
	if app == nil {
		// ask to be registered
		let result = workspace.registerApplication(path)

		// hopefully it doesn’t fail… if it does then print and fail
		if !result {
			print("Failed to register the \(identifier) app!")
			exit(1)
		}
	}
}

func registerPlugIn(identifier: String, path: URL) {
	// get all plugins matching ours – which, for whatever reason, returns all plugins if it can’t
	// find a match…
	let plugins = workspace.plugins(withIdentifiers: [ identifier ], protocols: nil, version: nil) as! [LSPlugInKitProxy]

	// …so filter to plugins matching our identifier
	let ourPlugin = plugins.filter { $0.pluginIdentifier == identifier }

	// if we got nothing back, we’re not registered
	if ourPlugin.count == 0 {
		// ask to be registered
		let result = workspace.registerPlugin(path)

		// hopefully it doesn’t fail… if it does then print and fail
		if !result {
			print("Failed to register the \(identifier) plugin!")
			exit(1)
		}
	}
}

func confirmPlugIns() -> DispatchTimeoutResult {
	// check to confirm PlugInKit is aware of our extensions
	let semaphore = DispatchSemaphore(value: 0)
	var discoverer: PKDiscoveryDriver! = nil

	discoverer = NSExtension.beginMatchingExtensions(attributes: [:], completion: { (result) -> Void in
		// get our results, hopefully
		if let actualResult = result as? [NSExtension] {
			// filter to ones that are hopefully ours
			let ours = actualResult.filter { $0.identifier.hasPrefix("ws.hbang.canzone.app.") }

			// if there are two, we’re good
			if ours.count == 2 {
				// swift pls
				NSExtension.end(matchingExtensions: discoverer)

				// tell the semaphore
				semaphore.signal()
			}
		}
	})

	// return the semaphore.wait() result – success or timedOut
	return semaphore.wait(timeout: DispatchTime.now() + 4)
}

// MARK: - Main

print("Registering components… This might take a moment.")

// register the app, followed by its plugins. ew this could be better :/
registerApp(identifier: "ws.hbang.canzone.app", path: URL(fileURLWithPath: "/Applications/Canzone.app"))
registerPlugIn(identifier: "ws.hbang.canzone.app.nowplayingwidget", path: URL(fileURLWithPath: "/Applications/Canzone.app/PlugIns/CanzoneNowPlayingWidget.appex"))
registerPlugIn(identifier: "ws.hbang.canzone.app.notificationcontent", path: URL(fileURLWithPath: "/Applications/Canzone.app/PlugIns/CanzoneNotificationContent.appex"))

// it should take only a fraction of a second if it works, so we assume a timeout means we never got
// anything. by the way, have i mentioned how god damn amazing swifty GCD is??
if confirmPlugIns() == .timedOut {
	print("⚠️ Hmm, failed… Please try installing or updating an app from the App Store to activate the widget.")
}
