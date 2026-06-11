import AppKit

/// Runs on the AppDelegate level — monitors the clipboard continuously
/// regardless of whether the main window is visible.
/// This is the single source of truth for clipboard polling.
@MainActor
final class ClipboardMonitor: ObservableObject {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let interval: TimeInterval

    /// Number of consecutive pasteboard reads to attempt after a change is detected.
    /// Some apps (especially browsers) write to the pasteboard asynchronously —
    /// the content may not be immediately available.
    private let retryReads = 3
    private let retryDelay: TimeInterval = 0.1

    @Published var isRunning = false

    init(interval: TimeInterval = 0.2) {
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

        // Some apps write pasteboard content asynchronously (e.g. browsers, Finder).
        // Retry a few times with small delays to catch the content once it appears.
        attemptRead(storage: storage, attempt: 0)
    }

    private func attemptRead(storage: StorageManager, attempt: Int) {
        // ── 1. Try reading rich text (HTML, RTF, etc.) — the most common "missing" content ──
        if let data = pasteboard.data(forType: .rtfd) ??
                      pasteboard.data(forType: .rtf) {
            let item = ClipboardItem(
                content: String(data: data, encoding: .utf8) ?? "[Rich Text]",
                type: "text"
            )
            storage.addItem(item)
            return
        }

        // ── 2. Try reading URL (Finder file copies, web links) ──
        if let urlString = pasteboard.string(forType: .URL),
           let url = URL(string: urlString) {
            let item = ClipboardItem(
                content: url.absoluteString,
                type: "text"
            )
            storage.addItem(item)
            return
        }

        // ── 3. Try reading file path (Finder "Copy as Pathname") ──
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingContentsConformToTypes: ["public.item"]
        ]) as? [URL], let first = fileURLs.first {
            let item = ClipboardItem(
                content: first.path,
                type: "text"
            )
            storage.addItem(item)
            return
        }

        // ── 4. Try reading image ──
        if let image = NSImage(pasteboard: pasteboard),
           let tiffData = image.tiffRepresentation {
            let item = ClipboardItem(content: "", imageData: tiffData, type: "image")
            storage.addItem(item)
            return
        }

        // ── 5. Try reading plain text (catch-all for everything else) ──
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let item = ClipboardItem(content: string, type: "text")
            storage.addItem(item)
            return
        }

        // ── 6. If nothing was readable but the pasteboard did change, retry ──
        //    (handles apps that write to pasteboard asynchronously)
        if attempt < retryReads {
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                // Only retry if no new pasteboard change happened in the meantime
                guard let self = self, self.pasteboard.changeCount == self.lastChangeCount else { return }
                self.attemptRead(storage: storage, attempt: attempt + 1)
            }
        }
    }
}
