import Foundation

@MainActor
final class CleanupManager {
    private var timer: Timer?

    func start(storage: StorageManager, retentionDays: Int = 7) {
        storage.cleanupOldItems(retentionDays: retentionDays)
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                storage.cleanupOldItems(retentionDays: retentionDays)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
