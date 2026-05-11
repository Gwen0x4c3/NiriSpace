import AppKit
import Common

func easeOutCubic(_ t: CGFloat) -> CGFloat {
    1 - pow(1 - t, 3)
}

@MainActor
final class NiriAnimationDriver {
    static let shared = NiriAnimationDriver()

    private var timer: DispatchSourceTimer?
    private var startTime: DispatchTime = .now()
    private var duration: TimeInterval = 0.3
    private var fromOffset: CGFloat = 0
    private var toOffset: CGFloat = 0
    private weak var targetContainer: TilingContainer?

    var isAnimating: Bool { timer != nil }
    func isAnimating(container: TilingContainer) -> Bool { isAnimating && targetContainer === container }

    func startAnimation(container: TilingContainer, from: CGFloat, to: CGFloat) {
        guard config.niriScrollAnimationDuration > 0 else {
            stopAnimation()
            return
        }
        // If already animating, update target from current animated position
        if isAnimating(container: container) {
            fromOffset = container.getUserData(key: TilingContainer.niriAnimatedOffsetKey) ?? from
            toOffset = to
            duration = TimeInterval(config.niriScrollAnimationDuration) / 1000.0
            startTime = .now()
            return
        } else if isAnimating {
            stopAnimation()
        }

        targetContainer = container
        fromOffset = from
        toOffset = to
        duration = TimeInterval(config.niriScrollAnimationDuration) / 1000.0
        startTime = .now()

        // 120fps timer for smooth animation
        let timerSource = DispatchSource.makeTimerSource(queue: .main)
        timerSource.schedule(deadline: .now(), repeating: .milliseconds(8))
        timerSource.setEventHandler { [weak self] in
            Task { @MainActor in
                await self?.tick()
            }
        }
        timerSource.resume()
        timer = timerSource
    }

    func stopAnimation() {
        targetContainer?.cleanUserData(key: TilingContainer.niriAnimatedOffsetKey)
        timer?.cancel()
        timer = nil
        targetContainer = nil
    }

    private func tick() async {
        guard let container = targetContainer else {
            stopAnimation()
            return
        }
        guard let workspace = container.nodeWorkspace,
              workspace.isVisible,
              focus.workspace == workspace
        else {
            stopAnimation()
            return
        }

        let elapsed = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000.0
        let t = CGFloat(min(elapsed / duration, 1.0))
        let interpolated = fromOffset + (toOffset - fromOffset) * easeOutCubic(t)
        container.putUserData(key: TilingContainer.niriAnimatedOffsetKey, data: interpolated)

        // Re-layout just this workspace
        try? await workspace.layoutWorkspace()

        if t >= 1.0 {
            // Animation complete: keep niriLastViewportOffsetKey, clean transient state.
            stopAnimation()
            scheduleCancellableCompleteRefreshSession(.hotkeyBinding)
        }
    }
}
