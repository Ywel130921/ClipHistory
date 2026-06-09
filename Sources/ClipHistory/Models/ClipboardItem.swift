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
            return "[图片]"
        }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 80 {
            return String(trimmed.prefix(80)) + "..."
        }
        return trimmed.isEmpty ? "(空内容)" : trimmed
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 10 {
            return "刚刚"
        } else if interval < 60 {
            return "\(Int(interval))秒前"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))小时前"
        } else {
            return "\(Int(interval / 86400))天前"
        }
    }

    var contentLengthInfo: String {
        if type == "image" {
            return "图片"
        }
        let count = content.count
        if count < 1000 {
            return "\(count) 字符"
        } else {
            return String(format: "%.1fK 字符", Double(count) / 1000.0)
        }
    }

    var lineCount: Int {
        content.split(separator: "\n").count
    }

    var detailLine: String {
        if type == "image" {
            return "图片"
        }
        let lines = lineCount
        if lines > 1 {
            return "\(contentLengthInfo) · \(lines) 行"
        }
        return contentLengthInfo
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}
