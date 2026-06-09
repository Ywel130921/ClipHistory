# ClipHistory

A native macOS menu bar application that monitors and stores your clipboard history. Copy text or images, and ClipHistory keeps a searchable record so you can quickly re-copy any previous entry.

## Features

- **Clipboard Monitoring** - Automatically captures text and image clipboard content in real-time
- **Menu Bar Integration** - Lives in the macOS status bar with hover popover for quick access
- **Search & Filter** - Instantly search through your clipboard history
- **Pin Items** - Pin important entries to keep them safe from automatic cleanup
- **Auto Cleanup** - Unpinned items older than 7 days are removed automatically
- **Image Support** - Stores both text and image (TIFF) clipboard content
- **Persistent Storage** - History survives app restarts via JSON-based local storage

## Requirements

- macOS 14.0+ (Sonoma)
- Apple Silicon Mac (`arm64`)

## Build & Run

```bash
# Build and run
./script/build_and_run.sh
```

Additional options:

```bash
./script/build_and_run.sh --debug       # Launch with LLDB debugger
./script/build_and_run.sh --logs        # Run + stream system logs
./script/build_and_run.sh --telemetry   # Run + stream logs filtered by bundle ID
./script/build_and_run.sh --verify      # Run + verify the process is alive
```

The compiled `.app` bundle will be placed in `dist/ClipHistory.app`.

## Usage

- **Hover** the menu bar icon to see the 5 most recent clipboard entries
- **Left click** the icon to open the full clipboard history window
- **Right click** the icon for quick actions (show history / quit)
- **Click** any item in the list to re-copy it to the clipboard
- **Pin** an item via right-click or hover to protect it from auto-cleanup

## Project Structure

```
Sources/ClipHistory/
├── ClipHistoryApp.swift          # App entry point
├── AppDelegate.swift             # Menu bar (NSStatusItem) setup
├── Models/
│   └── ClipboardItem.swift       # Clipboard entry data model
├── Services/
│   ├── ClipboardMonitor.swift    # NSPasteboard polling service
│   ├── StorageManager.swift      # JSON persistence
│   └── CleanupManager.swift      # Periodic old entry cleanup
└── Views/
    ├── ContentView.swift         # Main history window
    ├── ClipboardItemRow.swift    # Individual item row view
    └── HoverPanelView.swift      # Menu bar hover popover
```

## Tech Stack

- **Swift 5** with **SwiftUI** + **AppKit** interop
- **Swift Package Manager** project definition
- No external dependencies — Apple frameworks only
