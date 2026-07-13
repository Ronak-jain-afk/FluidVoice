import Foundation

protocol ApplicationLifecycleProtocol {
    func onStartup()
    func onShutdown()
    func onSleep()
    func onWake()
}
