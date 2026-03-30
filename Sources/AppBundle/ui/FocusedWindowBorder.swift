import AppKit

public final class FocusedWindowBorderPanel: NSPanelHud {
    @MainActor public static let shared = FocusedWindowBorderPanel()

    private let borderView = FocusedWindowBorderView()

    override private init() {
        super.init()
        hasShadow = false
        ignoresMouseEvents = true
        isOpaque = false
        backgroundColor = .clear
        contentView = NSView(frame: .zero)
        contentView?.wantsLayer = true
        contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        borderView.frame = .zero
        contentView?.addSubview(borderView)
    }

    @MainActor
    public func refresh() async throws {
        guard TrayMenuModel.shared.isEnabled, config.focusedWindowBorderEnabled else {
            close()
            return
        }
        guard let window = focus.windowOrNil else {
            close()
            return
        }
        let isMacosFullscreen = try await window.isMacosFullscreen
        let isMacosMinimized = try await window.isMacosMinimized
        if isMacosFullscreen || isMacosMinimized || window.isHiddenInCorner {
            close()
            return
        }
        guard let rect = try await window.getAxRect() else {
            close()
            return
        }

        let borderWidth = CGFloat(config.focusedWindowBorderWidth)
        let frame = rect.toGlobalPanelFrame(outset: borderWidth)
        borderView.update(width: borderWidth, color: NSColor.controlAccentColor)
        borderView.frame = NSRect(origin: .zero, size: frame.size)
        setFrame(frame, display: true)
        orderFrontRegardless()
    }
}

private final class FocusedWindowBorderView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    func update(width: CGFloat, color: NSColor) {
        guard let layer else { return }
        layer.borderWidth = width
        layer.cornerRadius = 12
        layer.borderColor = color.withAlphaComponent(0.95).cgColor
        layer.backgroundColor = NSColor.clear.cgColor
    }
}

extension Rect {
    fileprivate func toGlobalPanelFrame(outset: CGFloat) -> NSRect {
        let originY = mainMonitor.height - maxY - outset
        return NSRect(
            x: minX - outset,
            y: originY,
            width: width + 2 * outset,
            height: height + 2 * outset,
        )
    }
}
