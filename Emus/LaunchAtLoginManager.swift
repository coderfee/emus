import Foundation
import ServiceManagement
import OSLog
import Combine

@MainActor
class LaunchAtLoginManager: ObservableObject {
    private let logger = Logger(subsystem: "com.coderfee.emus", category: "LaunchAtLogin")
    private let service = SMAppService.mainApp
    
    @Published var isEnabled: Bool = false
    
    init() {
        refreshStatus()
    }
    
    func refreshStatus() {
        self.isEnabled = (service.status == .enabled)
    }
    
    func toggle() {
        let isCurrentlyRegistered = (service.status == .enabled)
        
        if isEnabled == isCurrentlyRegistered {
            return
        }
        
        Task { @MainActor in
            if isEnabled {
                do {
                    try service.register()
                    logger.info("Registered")
                } catch {
                    logger.error("Register failed: \(error)")
                    isEnabled = false
                }
            } else {
                do {
                    try await service.unregister()
                    logger.info("Unregistered")
                } catch {
                    logger.error("Unregister failed: \(error)")
                    isEnabled = true
                }
            }
        }
    }
}
