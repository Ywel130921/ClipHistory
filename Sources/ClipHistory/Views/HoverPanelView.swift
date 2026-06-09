import SwiftUI

struct HoverPanelView: View {
    @ObservedObject var storage = StorageManager.shared
    var onPopoverHoverEnter: (() -> Void)?
    var onPopoverHoverExit: (() -> Void)?

    var body: some View {
        let recent = storage.recentItems(count: 8)

        VStack(alignment: .leading, spacing: 0) {
            // ── Header ──
            headerView(count: storage.items.count)

            if recent.isEmpty {
                emptyView
            } else {
                // ── Items ──
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(recent.enumerated()), id: \.element.id) { index, item in
                            itemRow(item: item, isLast: item.id == recent.last?.id)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .opacity
                                    )
                                )
                                .animation(.spring(response: 0.35, dampingFraction: 0.8).delay(Double(index) * 0.03), value: recent.count)
                        }
                    }
                }
            }
        }
        .frame(width: 320)
        .onHover { hovering in
            if hovering {
                onPopoverHoverEnter?()
            } else {
                onPopoverHoverExit?()
            }
        }
    }

    // MARK: - Header

    private func headerView(count: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.blue)

            Text("剪贴板历史")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.quaternary)
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 6) {
            Spacer().frame(height: 12)
            Image(systemName: "clipboard")
                .font(.system(size: 20))
                .foregroundStyle(.tertiary)
            Text("暂无剪贴记录")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text("复制内容后自动显示")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            Spacer().frame(height: 12)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Item Row

    @ViewBuilder
    private func itemRow(item: ClipboardItem, isLast: Bool) -> some View {
        HoverItemRow(item: item)
            .padding(.horizontal, 8)
        if !isLast {
            Divider()
                .padding(.leading, 50)
                .padding(.trailing, 14)
        }
    }
}

// MARK: - HoverItemRow

struct HoverItemRow: View {
    let item: ClipboardItem
    @State private var isHovering = false
    @State private var showCopiedFeedback = false

    var body: some View {
        HStack(spacing: 10) {
            // ── Type indicator ──
            typeIcon

            // ── Content ──
            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .lineLimit(1)
                    .font(.system(size: 11.5, weight: item.isPinned ? .medium : .regular))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    // Detail info (char count / image tag)
                    Text(item.detailLine)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.tertiary)

                    if !item.isPinned {
                        Text("·")
                            .font(.system(size: 8))
                            .foregroundStyle(.quaternary)
                        Text(item.timeAgo)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer(minLength: 4)

            // ── Right side: pin + time (for pinned) + copy feedback ──
            VStack(alignment: .trailing, spacing: 2) {
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.orange)
                    Text(item.timeAgo)
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }

                if showCopiedFeedback {
                    Text("已复制")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.blue)
                        .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    isHovering
                        ? Color.primary.opacity(0.06)
                        : Color.clear
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.15)) {
                showCopiedFeedback = true
            }
            StorageManager.shared.copyToClipboard(item: item)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.15)) {
                    showCopiedFeedback = false
                }
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
    }

    // MARK: - Type Icon

    @ViewBuilder
    private var typeIcon: some View {
        if item.type == "image" {
            if let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.quaternary)
                    Image(systemName: "photo")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 32, height: 32)
            }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(item.isPinned
                        ? Color.orange.opacity(0.12)
                        : Color.primary.opacity(0.04)
                    )
                Text(String(item.content.prefix(1)).uppercased())
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(item.isPinned ? .orange : .secondary)
            }
            .frame(width: 32, height: 32)
        }
    }
}
