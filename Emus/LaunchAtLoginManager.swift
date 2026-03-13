import Foundation
import ServiceManagement
import OSLog
import Combine

@MainActor
class LaunchAtLoginManager: ObservableObject {
    private let logger = Logger(subsystem: "com.coderfee.Emus", category: "LaunchAtLogin")
    private let service = SMAppService.mainApp
    
    @Published var isEnabled: Bool = false
    
    init() {
        refreshStatus()
    }
    
    func refreshStatus() {
        self.isEnabled = (service.status == .enabled)
    }
    
    func toggle() {
        if isEnabled {
            do {
                try service.register()
                logger.info("Registered")
            } catch {
                logger.error("Register failed: \(error)")
                isEnabled = false
            }
        } else {
            service.unregister { [weak self] error in
                if let error = error {
                    self?.logger.error("Unregister failed: \(error)")
                    Task { @MainActor in self?.isEnabled = true }
                }
            }
        }
    }
}
