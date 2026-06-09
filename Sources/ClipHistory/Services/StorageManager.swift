import AppKit
import Foundation

@MainActor
final class StorageManager: ObservableObject {
    static let shared = StorageManager()

    @Published var items: [ClipboardItem] = []
    var skipNextClipboardChange = false

    private let storageURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ClipHistory")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        storageURL = dir.appendingPathComponent("history.json")
        load()
    }

    func addItem(_ item: ClipboardItem) {
        if skipNextClipboardChange {
            skipNextClipboardChange = false
            return
        }
        if let last = items.first, last.type == item.type && last.content == item.content && last.imageData == item.imageData {
            return
        }
        items.insert(item, at: 0)
        save()
    }

    func togglePin(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isPinned.toggle()
        save()
    }

    func delete(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func deleteAll() {
        items.removeAll()
        save()
    }

    func cleanupOldItems(retentionDays: Int = 7) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        let before = items.count
        items.removeAll { !$0.isPinned && $0.timestamp < cutoff }
        if items.count != before { save() }
    }

    func recentItems(count: Int = 5) -> [ClipboardItem] {
        Array(items.prefix(count))
    }

    func copyToClipboard(item: ClipboardItem) {
        skipNextClipboardChange = true
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if item.type == "image", let imageData = item.imageData,
           let image = NSImage(data: imageData) {
            pasteboard.writeObjects([image])
        } else {
            pasteboard.setString(item.content, forType: .string)
        }
    }

    private func save() {
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? decoder.decode([ClipboardItem].self, from: data) else { return }
        items = decoded
    }
}
