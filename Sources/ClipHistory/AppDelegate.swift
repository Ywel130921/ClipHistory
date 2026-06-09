import SwiftUI
import AppKit
import Combine

extension NSImage {
    /// Creates a template-status-bar icon: a clipboard with text lines
    static func statusBarClipboardIcon() -> NSImage {
        let s: CGFloat = 20  // base size (will be rendered at @2x for sharpness)
        let img = NSImage(size: NSSize(width: s, height: s), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let d: CGFloat = rect.width  // = 20
            let scale: CGFloat = d / 20

            ctx.setShouldAntialias(true)

            // ── Clipboard board ──
            let board = CGRect(x: 2 * scale, y: 1.5 * scale, width: 16 * scale, height: 17 * scale)
            let bPath = NSBezierPath(roundedRect: board, xRadius: 3 * scale, yRadius: 3 * scale)
            NSColor.black.withAlphaComponent(0.85).setStroke()
            bPath.lineWidth = 1.8 * scale
            bPath.stroke()

            // ── Top clip ──
            let clipPath = NSBezierPath()
            let cx = rect.midX
            let cy = board.maxY + 0.5 * scale
            clipPath.move(to: NSPoint(x: cx - 4 * scale, y: cy))
            clipPath.line(to: NSPoint(x: cx - 4 * scale, y: cy + 3 * scale))
            clipPath.curve(
                to: NSPoint(x: cx + 4 * scale, y: cy + 3 * scale),
                controlPoint1: NSPoint(x: cx - 2 * scale, y: cy + 4.5 * scale),
                controlPoint2: NSPoint(x: cx + 2 * scale, y: cy + 4.5 * scale)
            )
            clipPath.line(to: NSPoint(x: cx + 4 * scale, y: cy))
            NSColor.black.withAlphaComponent(0.6).setStroke()
            clipPath.lineWidth = 1.6 * scale
            clipPath.lineCapStyle = .round
            clipPath.stroke()

            // ── Text lines ──
            let lx = board.minX + 2.5 * scale
            let ly0 = board.minY + 3 * scale
            let spacing = 3 * scale
            let widths: [CGFloat] = [10, 8.5, 11, 7, 9.5]
            for (i, w) in widths.enumerated() {
                let y = ly0 + CGFloat(i) * spacing
                let line = NSBezierPath()
                line.move(to: NSPoint(x: lx, y: y))
                line.line(to: NSPoint(x: lx + w * scale, y: y))
                NSColor.black.withAlphaComponent(i == 0 ? 0.75 : 0.50).setStroke()
                line.lineWidth = 1.5 * scale
                line.lineCapStyle = .round
                line.stroke()
            }

            // ── Accent dot on first line ──
            let dot = NSBezierPath(ovalIn: CGRect(
                x: lx - 3.2 * scale,
                y: ly0 + 2 * scale,
                width: 2.2 * scale,
                height: 2.2 * scale
            ))
            NSColor.black.withAlphaComponent(0.5).setFill()
            dot.fill()

            return true
        }
        img.isTemplate = true
        return img
    }
}

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

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    private var hideWorkItem: DispatchWorkItem?
    private let hideDelay: TimeInterval = 0.3
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        // Observe storage changes to update the status bar badge in real time
        StorageManager.shared.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.updateStatusBarBadge(count: items.count)
            }
            .store(in: &cancellables)
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }

        // Use a custom drawn clipboard icon for the status bar
        button.image = NSImage.statusBarClipboardIcon()

        // Setup popover for hover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 280)
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
        let countItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        countItem.isEnabled = false
        countItem.tag = 100
        menu.addItem(countItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu

        // Left click opens main window
        button.target = self
        button.action = #selector(statusBarButtonClicked)
        button.sendAction(on: [.leftMouseUp])
    }

    private func updateStatusBarBadge(count: Int) {
        // Update the right-click menu item
        if let menu = statusItem?.menu,
           let countItem = menu.item(withTag: 100) {
            countItem.title = "共 \(count) 条记录"
        }
    }

    func showPopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        // Update popover content size based on actual item count
        let count = StorageManager.shared.items.count
        let height = count > 0 ? min(CGFloat(count) * 58 + 40, 320) : 80
        popover.contentSize = NSSize(width: 320, height: height)
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
