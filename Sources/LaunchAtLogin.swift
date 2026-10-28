import Foundation
import ServiceManagement

protocol LoginItemServicing {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

extension SMAppService: LoginItemServicing {}

final class LaunchAtLoginController {
    private let service: LoginItemServicing
    private let defaults: UserDefaults
    private let configuredKey = "launchAtLoginConfigured"

    init(service: LoginItemServicing = SMAppService.mainApp, defaults: UserDefaults = .standard) {
        self.service = service
        self.defaults = defaults
    }

    var status: SMAppService.Status { service.status }

    func enableByDefaultIfNeeded() throws {
        guard !defaults.bool(forKey: configuredKey) else { return }
        // Make one default attempt. Never override a later choice in System Settings.
        defaults.set(true, forKey: configuredKey)
        try setEnabled(true)
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if status != .enabled && status != .requiresApproval {
                try service.register()
            }
        } else if status == .enabled || status == .requiresApproval {
            try service.unregister()
        }
        defaults.set(true, forKey: configuredKey)
    }
}
