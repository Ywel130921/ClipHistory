import SwiftUI
import AppKit

class StatusButton: NSView {
    var onMouseEntered: (() -> Void)?
    var onMouseExited: (() -> Void)?
    private var trackingArea: NSTrackingArea?

    override var acceptsFirstResponder: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let old = trackingArea { removeTrackingArea(old) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        onMouseEntered?()
    }

    override func mouseExited(with event: NSEvent) {
        onMouseExited?()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    private var hideWorkItem: DispatchWorkItem?
    private let hideDelay: TimeInterval = 0.3

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }

        if let img = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipHistory") {
            img.isTemplate = true
            button.image = img
        }

        // Setup popover for hover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 200)
        popover?.behavior = .semitransient
        popover?.animates = true

        // Create HoverPanelView with callbacks to coordinate dismiss
        let hoverPanel = HoverPanelView(
            onPopoverHoverEnter: { [weak self] in
                self?.cancelHidePopover()
            },
            onPopoverHoverExit: { [weak self] in
                self?.scheduleHidePopover()
            }
        )
        popover?.contentViewController = NSHostingController(rootView: hoverPanel)

        // Wrap the button in a StatusButton for hover tracking
        let statusButton = StatusButton(frame: button.bounds)
        statusButton.autoresizingMask = [.width, .height]
        statusButton.onMouseEntered = { [weak self] in
            self?.cancelHidePopover()
            self?.showPopover()
        }
        statusButton.onMouseExited = { [weak self] in
            self?.scheduleHidePopover()
        }
        button.addSubview(statusButton)

        // Right-click menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Clipboard History", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu

        // Left click opens main window
        button.target = self
        button.action = #selector(statusBarButtonClicked)
        button.sendAction(on: [.leftMouseUp])
    }

    func showPopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func hidePopover() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        popover?.performClose(nil)
    }

    func scheduleHidePopover() {
        hideWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.hidePopover()
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + hideDelay, execute: work)
    }

    func cancelHidePopover() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
    }

    @objc func statusBarButtonClicked() {
        hidePopover()
        showMainWindow()
    }

    @objc func showMainWindow() {
        for window in NSApp.windows {
            if window.isKeyWindow || window.canBecomeKey {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
