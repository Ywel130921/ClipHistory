import SwiftUI

struct ContentView: View {
    @ObservedObject private var storage = StorageManager.shared
    @StateObject private var clipboardMonitor = ClipboardMonitor()
    @State private var cleanupManager = CleanupManager()
    @State private var searchText = ""
    @State private var showPinnedOnly = false
    @State private var selectedItemID: UUID?
    @State private var hoveredItemID: UUID?
    @State private var showDeleteAllConfirmation = false

    private var filteredItems: [ClipboardItem] {
        storage.items.filter { item in
            let matchesSearch = searchText.isEmpty || item.content.localizedCaseInsensitiveContains(searchText)
            let matchesPinned = !showPinnedOnly || item.isPinned
            return matchesSearch && matchesPinned
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            Divider()
            if filteredItems.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .alert("Delete All History", isPresented: $showDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                storage.deleteAll()
                selectedItemID = nil
            }
        } message: {
            Text("This will permanently delete all clipboard history, including pinned items. This action cannot be undone.")
        }
        .onAppear {
            clipboardMonitor.start(storage: storage)
            cleanupManager.start(storage: storage)
        }
        .onDisappear {
            clipboardMonitor.stop()
            cleanupManager.stop()
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "doc.on.clipboard")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Clipboard History")
                    .font(.headline)
                Spacer()
                if !storage.items.isEmpty {
                    Button {
                        showDeleteAllConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete all history")
                }
                Button {
                    showPinnedOnly.toggle()
                } label: {
                    Image(systemName: showPinnedOnly ? "pin.fill" : "pin")
                        .foregroundStyle(showPinnedOnly ? .orange : .secondary)
                }
                .buttonStyle(.plain)
                .help(showPinnedOnly ? "Show all" : "Show pinned only")
            }
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredItems) { item in
                    Button {
                        storage.copyToClipboard(item: item)
                        selectedItemID = item.id
                    } label: {
                        ClipboardItemRow(
                            item: item,
                            isSelected: selectedItemID == item.id,
                            onTogglePin: { storage.togglePin(id: $0) },
                            onDelete: { storage.delete(id: $0) }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: searchText.isEmpty ? "clipboard" : "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text(searchText.isEmpty ? "No clipboard history yet" : "No results found")
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "Copy something to get started" : "Try a different search")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }

}
