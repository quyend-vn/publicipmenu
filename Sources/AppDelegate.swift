import AppKit
import Network
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let pasteboard: NSPasteboard
    private let launchAtLogin: LaunchAtLoginController

    init(pasteboard: NSPasteboard = .general, launchAtLogin: LaunchAtLoginController = LaunchAtLoginController()) {
        self.pasteboard = pasteboard
        self.launchAtLogin = launchAtLogin
        super.init()
    }

    private var statusItem: NSStatusItem!
    private var address: String?
    private var timer: Timer?
    private var task: URLSessionDataTask?
    private var generation = 0
    private var feedback = 0
    private let monitor = NWPathMonitor()
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 15
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Launch Services normally reuses the running instance; guard direct launches too.
        if NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "local.publicip.menu").count > 1 {
            NSApp.terminate(nil)
            return
        }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.imagePosition = .imageLeading
            button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        render(title: "…", symbol: "globe", tooltip: "Checking public IP…")
        do {
            try launchAtLogin.enableByDefaultIfNeeded()
        } catch {
            DispatchQueue.main.async { [weak self] in self?.showLoginItemError(error) }
        }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
        timer?.tolerance = 5
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(wokeUp), name: NSWorkspace.didWakeNotification, object: nil)
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.generation += 1
                self.task?.cancel()
                self.task = nil
                self.address = nil
                if connected {
                    self.render(title: "…", symbol: "globe", tooltip: "Checking public IP…")
                    self.refresh()
                } else {
                    self.render(title: "Offline", symbol: "wifi.slash", tooltip: "No network connection. Click to retry.")
                }
            }
        }
        monitor.start(queue: DispatchQueue(label: "local.publicip.network"))
    }

    private func render(title: String, symbol: String, tooltip: String) {
        feedback += 1
        guard let button = statusItem.button else { return }
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Public IP")
        image?.isTemplate = true
        button.image = image
        button.title = " " + title
        button.toolTip = tooltip
        button.setAccessibilityLabel("Public IP: " + title)
        button.setAccessibilityHelp(tooltip)
    }

    @objc private func refresh() {
        guard task == nil else { return }
        generation += 1
        let requestGeneration = generation
        var request = URLRequest(url: URL(string: "https://checkip.amazonaws.com/")!)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        task = session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self, requestGeneration == self.generation else { return }
                self.task = nil
                guard error == nil,
                      let response = response as? HTTPURLResponse,
                      response.statusCode == 200,
                      let data = data,
                      let ip = IPAddress.parse(data) else {
                    self.address = nil
                    self.render(title: "IP unavailable", symbol: "exclamationmark.circle", tooltip: "Could not fetch public IP. Click to retry; right-click for options.")
                    return
                }
                self.address = ip
                self.render(title: ip, symbol: "globe", tooltip: "Click to copy \(ip) · Right-click for options · Refreshes every minute")
            }
        }
        task?.resume()
    }

    @objc private func wokeUp() {
        generation += 1
        task?.cancel()
        task = nil
        address = nil
        render(title: "…", symbol: "globe", tooltip: "Refreshing public IP…")
        refresh()
    }

    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else {
            copyAddress()
        }
    }

    @objc private func copyAddress() {
        guard let address = address else { refresh(); return }
        pasteboard.clearContents()
        guard pasteboard.setString(address, forType: .string) else { return }
        render(title: address, symbol: "checkmark", tooltip: "Copied \(address)")
        let currentFeedback = feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self, self.feedback == currentFeedback, self.address == address else { return }
            self.render(title: address, symbol: "globe", tooltip: "Click to copy \(address) · Right-click for options · Refreshes every minute")
        }
    }

    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        let heading = NSMenuItem(title: address ?? "Public IP unavailable", action: nil, keyEquivalent: "")
        heading.isEnabled = false
        menu.addItem(heading)
        let copy = NSMenuItem(title: "Copy IP", action: #selector(copyAddress), keyEquivalent: "")
        copy.target = self
        copy.isEnabled = address != nil
        menu.addItem(copy)
        let refresh = NSMenuItem(title: "Refresh IP", action: #selector(refresh), keyEquivalent: "")
        refresh.target = self
        menu.addItem(refresh)
        menu.addItem(.separator())
        let loginStatus = launchAtLogin.status
        let enabled = loginStatus == .enabled
        let pending = loginStatus == .requiresApproval
        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        login.target = self
        login.state = enabled ? .on : (pending ? .mixed : .off)
        menu.addItem(login)
        if pending {
            login.toolTip = "Approval required in System Settings. Click to disable."
            let settings = NSMenuItem(title: "Open Login Items Settings…", action: #selector(openLoginItemsSettings), keyEquivalent: "")
            settings.target = self
            menu.addItem(settings)
        }
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Public IP", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        return menu
    }

    private func showMenu() {
        guard let button = statusItem.button else { return }
        statusItem.menu = makeMenu()
        button.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleLaunchAtLogin() {
        let status = launchAtLogin.status
        updateLaunchAtLogin(status != .enabled && status != .requiresApproval)
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLogin.setEnabled(enabled)
            if enabled && launchAtLogin.status == .requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
            }
        } catch {
            showLoginItemError(error)
        }
    }

    @objc private func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    private func showLoginItemError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Could not update Launch at Login"
        alert.informativeText = "\(error.localizedDescription) You can try again from the menu or check System Settings > General > Login Items."
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        task?.cancel()
        monitor.cancel()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
