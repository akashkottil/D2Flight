import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "Monitor")
    
    @Published var isConnected = true
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        networkMonitor.start(queue: workerQueue)
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                print("🌐 Network status: \(path.status == .satisfied ? "Connected" : "Disconnected")")
            }
        }
    }
    
    deinit {
        networkMonitor.cancel()
    }
}
