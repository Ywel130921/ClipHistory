import AppKit

@MainActor
final class ClipboardMonitor: ObservableObject {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let interval: TimeInterval

    @Published var isRunning = false

    init(interval: TimeInterval = 0.3) {
        self.interval = interval
        self.lastChangeCount = pasteboard.changeCount
    }

    func start(storage: StorageManager) {
        guard !isRunning else { return }
        isRunning = true
        lastChangeCount = pasteboard.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard(storage: storage)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func checkClipboard(storage: StorageManager) {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Try image first
        if let image = NSImage(pasteboard: pasteboard),
           let tiffData = image.tiffRepresentation {
            let item = ClipboardItem(content: "", imageData: tiffData, type: "image")
            storage.addItem(item)
            return
        }

        // Try text
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let item = ClipboardItem(content: string, type: "text")
            storage.addItem(item)
        }
    }
}
