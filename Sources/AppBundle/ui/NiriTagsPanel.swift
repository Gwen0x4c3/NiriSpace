import AppKit

public final class NiriTagsPanel: NSPanelHud {
    @MainActor public static let shared = NiriTagsPanel()

    private let tagsView = NiriTagsView()

    override private init() {
        super.init()
        hasShadow = false
        ignoresMouseEvents = true
        isOpaque = false
        backgroundColor = .clear
        contentView = NSView(frame: .zero)
        contentView?.wantsLayer = true
        contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        tagsView.frame = .zero
        contentView?.addSubview(tagsView)
    }

    @MainActor
    func refresh() {
        guard TrayMenuModel.shared.isEnabled,
              let window = focus.windowOrNil,
              let (_, column) = niriRootColumn(for: window),
              let stack = column as? TilingContainer,
              stack.orientation == .v,
              stack.layout == .tabbed,
              stack.children.count > 1,
              let columnRect = stack.lastAppliedLayoutPhysicalRect,
              let focusedChild = window.directChild(of: stack),
              let activeIndex = focusedChild.ownIndex
        else {
            close()
            return
        }

        let frame = columnRect.niriTagsPanelFrame(width: 10, gap: 6)
        tagsView.update(count: stack.children.count, activeIndex: activeIndex)
        tagsView.frame = NSRect(origin: .zero, size: frame.size)
        setFrame(frame, display: true)
        orderFrontRegardless()
    }
}

private final class NiriTagsView: NSView {
    private var count = 0
    private var activeIndex = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    func update(count: Int, activeIndex: Int) {
        self.count = count
        self.activeIndex = activeIndex
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard count > 0 else { return }
        let segmentHeight = bounds.height / CGFloat(count)
        for index in 0..<count {
            let rect = NSRect(
                x: 0,
                y: bounds.height - CGFloat(index + 1) * segmentHeight,
                width: bounds.width,
                height: segmentHeight,
            ).insetBy(dx: 0, dy: 2)
            let color = index == activeIndex
                ? NSColor.systemGreen.withAlphaComponent(0.95)
                : NSColor.systemBlue.withAlphaComponent(0.45)
            let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
            color.setFill()
            path.fill()
        }
    }
}

private extension Rect {
    func niriTagsPanelFrame(width: CGFloat, gap: CGFloat) -> NSRect {
        let x = max(0, minX - width - gap)
        return NSRect(
            x: x,
            y: mainMonitor.height - maxY,
            width: width,
            height: height,
        )
    }
}
