import SwiftUI

struct HoverPanelView: View {
    @ObservedObject var storage = StorageManager.shared

    var body: some View {
        let recent = storage.recentItems(count: 5)

        VStack(alignment: .leading, spacing: 0) {
            if recent.isEmpty {
                Text("No recent items")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                ForEach(recent) { item in
                    Button {
                        storage.copyToClipboard(item: item)
                    } label: {
                        HoverItemRow(item: item)
                    }
                    .buttonStyle(.plain)
                    if item.id != recent.last?.id {
                        Divider()
                            .padding(.horizontal, 8)
                    }
                }
            }
        }
        .frame(width: 300)
        .padding(.vertical, 6)
    }
}

struct HoverItemRow: View {
    let item: ClipboardItem
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            if item.type == "image" {
                if let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else {
                    Image(systemName: "photo")
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.secondary)
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.quaternary)
                    Text(String(item.content.prefix(1)).uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(item.preview)
                    .lineLimit(1)
                    .font(.system(size: 11))
                    .foregroundStyle(.primary)
                Text(item.timeAgo)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
    }
}
