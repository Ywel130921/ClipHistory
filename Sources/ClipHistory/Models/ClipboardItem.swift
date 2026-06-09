import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var imageData: Data?
    var type: String // "text" or "image"
    var timestamp: Date
    var isPinned: Bool

    init(content: String, imageData: Data? = nil, type: String = "text") {
        self.id = UUID()
        self.content = content
        self.imageData = imageData
        self.type = type
        self.timestamp = Date()
        self.isPinned = false
    }

    var preview: String {
        if type == "image" {
            return "[Image]"
        }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 120 {
            return String(trimmed.prefix(120)) + "..."
        }
        return trimmed
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}
