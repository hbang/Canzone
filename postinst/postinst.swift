import MobileCoreServices

let workspace = LSApplicationWorkspace.default()!

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

func registerPlugin(identifier: String, path: URL) {
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

print("Registering components… This might take a moment.")

// register the app, followed by its plugins. ew this could be better :/
registerApp(identifier: "ws.hbang.canzone.app", path: URL(fileURLWithPath: "/Applications/Canzone.app"))
registerPlugin(identifier: "ws.hbang.canzone.app.nowplayingwidget", path: URL(fileURLWithPath: "/Applications/Canzone.app/PlugIns/CanzoneNowPlayingWidget.appex"))
registerPlugin(identifier: "ws.hbang.canzone.app.notificationcontent", path: URL(fileURLWithPath: "/Applications/Canzone.app/PlugIns/CanzoneNotificationContent.appex"))
