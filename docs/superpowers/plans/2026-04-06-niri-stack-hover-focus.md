# Niri stack/unstack and hover-focus Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add niri-only `window-stack` / `window-unstack` commands plus an opt-in `niri-mouse-follows-focus` config that changes hover focus without recentering the niri viewport.

**Architecture:** Introduce two dedicated commands for niri column stack management, add one config flag for hover-driven focus, and thread a small focus-side state through layout so hover changes update focus/native activation but do not change niri centering until a real click/native focus change occurs.

**Tech Stack:** Swift, XCTest, existing AeroSpace/NiriSpace command parser, tree/layout engine, AppKit global event monitors.

---

### File map

**Modify:**
- `Sources/Common/cmdArgs/cmdArgsManifest.swift` — register new command kinds and parsers.
- `Sources/Common/cmdHelpGenerated.swift` — add help strings for the new commands.
- `Sources/Cli/subcommandDescriptionsGenerated.swift` — list the new commands in CLI help.
- `Sources/AppBundle/command/cmdManifest.swift` — map parsed args to command implementations.
- `Sources/AppBundle/config/Config.swift` — add `niriMouseFollowsFocus` flag.
- `Sources/AppBundle/config/parseConfig.swift` — parse the new config key.
- `Sources/AppBundle/focus.swift` — add the smallest possible focus-side state for suppressing niri recentering on hover focus.
- `Sources/AppBundle/layout/layoutRecursive.swift` — teach niri viewport anchoring to honor the hover-focus suppression state.
- `Sources/AppBundle/GlobalObserver.swift` — add mouse-move monitoring and hover-focus dispatch.
- `README.md` — document commands, config, and default bindings example.
- `docs/config-examples/default-config.toml` — document the config and default bindings.

**Create:**
- `Sources/Common/cmdArgs/impl/WindowStackCmdArgs.swift`
- `Sources/Common/cmdArgs/impl/WindowUnstackCmdArgs.swift`
- `Sources/AppBundle/command/impl/WindowStackCommand.swift`
- `Sources/AppBundle/command/impl/WindowUnstackCommand.swift`
- `Sources/AppBundleTests/command/WindowStackCommandTest.swift`

**Test:**
- `Sources/AppBundleTests/command/NiriModeTest.swift`
- `Sources/AppBundleTests/config/ConfigTest.swift`
- `Sources/AppBundleTests/command/WindowStackCommandTest.swift`

### Task 1: Add failing parser/config tests first

**Files:**
- Create: `Sources/AppBundleTests/command/WindowStackCommandTest.swift`
- Modify: `Sources/AppBundleTests/config/ConfigTest.swift`

- [ ] **Step 1: Write failing parser and config tests**

```swift
@testable import AppBundle
import XCTest

@MainActor
final class WindowStackCommandTest: XCTestCase {
    func testParseWindowStackCommands() {
        XCTAssertTrue(parseCommand("window-stack").cmdOrNil is WindowStackCommand)
        XCTAssertTrue(parseCommand("window-unstack").cmdOrNil is WindowUnstackCommand)
    }
}
```

```swift
func testParseNiriMouseFollowsFocus() {
    let (config, errors) = parseConfig(
        """
        niri-mouse-follows-focus = true
        """
    )
    assertEquals(errors, [])
    XCTAssertTrue(config.niriMouseFollowsFocus)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter 'WindowStackCommandTest|ConfigTest/testParseNiriMouseFollowsFocus'`

Expected: FAIL with unknown command / missing config property or unknown top-level key.

- [ ] **Step 3: Add minimal parser/config scaffolding**

```swift
public enum CmdKind: String, CaseIterable, Equatable, Sendable {
    case windowStack = "window-stack"
    case windowUnstack = "window-unstack"
}
```

```swift
struct Config: ConvenienceCopyable {
    var niriMouseFollowsFocus: Bool = false
}
```

- [ ] **Step 4: Run tests to verify parsing/config passes**

Run: `swift test --filter 'WindowStackCommandTest|ConfigTest/testParseNiriMouseFollowsFocus'`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/Common/cmdArgs/cmdArgsManifest.swift Sources/AppBundle/config/Config.swift \
        Sources/AppBundle/config/parseConfig.swift Sources/AppBundleTests/command/WindowStackCommandTest.swift \
        Sources/AppBundleTests/config/ConfigTest.swift
git commit -m "test: add parser coverage for niri stack and hover focus"
```

### Task 2: Implement command parsing and help wiring

**Files:**
- Create: `Sources/Common/cmdArgs/impl/WindowStackCmdArgs.swift`
- Create: `Sources/Common/cmdArgs/impl/WindowUnstackCmdArgs.swift`
- Modify: `Sources/Common/cmdArgs/cmdArgsManifest.swift`
- Modify: `Sources/Common/cmdHelpGenerated.swift`
- Modify: `Sources/Cli/subcommandDescriptionsGenerated.swift`
- Modify: `Sources/AppBundle/command/cmdManifest.swift`

- [ ] **Step 1: Write the failing parser wiring**

```swift
public struct WindowStackCmdArgs: CmdArgs {
    public var commonState: CmdArgsCommonState
    fileprivate init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = .init(
        kind: .windowStack,
        allowInConfig: true,
        help: window_stack_help_generated,
        flags: ["--window-id": optionalWindowIdFlag()],
        posArgs: []
    )
}
```

```swift
func parseWindowStackCmdArgs(_ args: StrArrSlice) -> ParsedCmd<WindowStackCmdArgs> {
    parseSpecificCmdArgs(WindowStackCmdArgs(rawArgs: args), args)
}
```

- [ ] **Step 2: Run the targeted parser test**

Run: `swift test --filter WindowStackCommandTest/testParseWindowStackCommands`

Expected: FAIL until both kinds, help constants, and command mappings exist.

- [ ] **Step 3: Complete parser/help/manifest wiring**

```swift
let window_stack_help_generated = """
    USAGE: window-stack [-h|--help] [--window-id <window-id>]
    """
let window_unstack_help_generated = """
    USAGE: window-unstack [-h|--help] [--window-id <window-id>]
    """
```

```swift
["  window-stack", "Stack the focused niri window onto the column to its left"],
["  window-unstack", "Unstack the focused niri window into its own column"],
```

- [ ] **Step 4: Run the parser test again**

Run: `swift test --filter WindowStackCommandTest/testParseWindowStackCommands`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/Common/cmdArgs/impl/WindowStackCmdArgs.swift Sources/Common/cmdArgs/impl/WindowUnstackCmdArgs.swift \
        Sources/Common/cmdArgs/cmdArgsManifest.swift Sources/Common/cmdHelpGenerated.swift \
        Sources/Cli/subcommandDescriptionsGenerated.swift Sources/AppBundle/command/cmdManifest.swift
git commit -m "feat: wire niri stack and unstack commands"
```

### Task 3: Implement failing niri stack/unstack behavior tests

**Files:**
- Modify: `Sources/AppBundleTests/command/WindowStackCommandTest.swift`

- [ ] **Step 1: Add failing behavior tests**

```swift
func testWindowStackInNiri() async throws {
    config.defaultRootContainerLayout = .niri
    let root = Workspace.get(byName: name).rootTilingContainer
    TestWindow.new(id: 1, parent: root)
    TestWindow.new(id: 2, parent: root)
    XCTAssertTrue(TestWindow.new(id: 3, parent: root).focusWindow())

    let result = try await parseCommand("window-stack").cmdOrDie.run(.defaultEnv, .emptyStdin)

    assertEquals(result.exitCode, 0)
    assertEquals(root.layoutDescription, .niri([.window(1), .v_tiles([.window(2), .window(3)])]))
    assertEquals(focus.windowOrNil?.windowId, 3)
}
```

```swift
func testWindowUnstackInNiri() async throws {
    config.defaultRootContainerLayout = .niri
    let root = Workspace.get(byName: name).rootTilingContainer
    TestWindow.new(id: 1, parent: root)
    TilingContainer.newVTiles(parent: root, adaptiveWeight: 1).apply {
        TestWindow.new(id: 2, parent: $0)
        XCTAssertTrue(TestWindow.new(id: 3, parent: $0).focusWindow())
    }

    let result = try await parseCommand("window-unstack").cmdOrDie.run(.defaultEnv, .emptyStdin)

    assertEquals(result.exitCode, 0)
    assertEquals(root.layoutDescription, .niri([.window(1), .v_tiles([.window(2)]), .window(3)]))
    assertEquals(focus.windowOrNil?.windowId, 3)
}
```

- [ ] **Step 2: Add failure-case tests**

```swift
func testWindowStackRequiresNiriAndLeftNeighbour() async throws {
    let root = Workspace.get(byName: name).rootTilingContainer
    XCTAssertTrue(TestWindow.new(id: 1, parent: root).focusWindow())

    let nonNiri = try await parseCommand("window-stack").cmdOrDie.run(.defaultEnv, .emptyStdin)
    XCTAssertEqual(nonNiri.exitCode, 1)

    config.defaultRootContainerLayout = .niri
    let workspace = Workspace.get(byName: name)
    try await workspace.layoutWorkspace()
}
```

- [ ] **Step 3: Run the stack test file to verify it fails**

Run: `swift test --filter WindowStackCommandTest`

Expected: FAIL because command behavior is not implemented yet.

- [ ] **Step 4: Commit the failing tests**

```bash
git add Sources/AppBundleTests/command/WindowStackCommandTest.swift
git commit -m "test: cover niri window stack and unstack behavior"
```

### Task 4: Implement `window-stack` and `window-unstack`

**Files:**
- Create: `Sources/AppBundle/command/impl/WindowStackCommand.swift`
- Create: `Sources/AppBundle/command/impl/WindowUnstackCommand.swift`

- [ ] **Step 1: Write minimal `window-stack` implementation**

```swift
struct WindowStackCommand: Command {
    let args: WindowStackCmdArgs
    let shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }
        guard let window = target.windowOrNil else { return io.err(noWindowIsFocused) }
        guard let column = window.parentsWithSelf.first(where: { ($0.parent as? TilingContainer)?.layout == .niri }) else {
            return io.err("window-stack currently works only for windows inside niri layout")
        }
        guard let root = column.parent as? TilingContainer, root.layout == .niri else { return false }
        guard let index = column.ownIndex, index > 0 else { return io.err("No left neighbour column to stack into") }

        let left = root.children[index - 1]
        let targetColumn = (left as? TilingContainer).takeIf { $0.orientation == .v } ??
            TilingContainer(parent: root, adaptiveWeight: left.getWeight(.h), .v, .tiles, index: index - 1)

        if left.parent === root && left !== targetColumn {
            _ = left.unbindFromParent()
            left.bind(to: targetColumn, adaptiveWeight: WEIGHT_AUTO, index: INDEX_BIND_LAST)
        }
        _ = window.unbindFromParent()
        window.bind(to: targetColumn, adaptiveWeight: WEIGHT_AUTO, index: INDEX_BIND_LAST)
        return true
    }
}
```

- [ ] **Step 2: Write minimal `window-unstack` implementation**

```swift
struct WindowUnstackCommand: Command {
    let args: WindowUnstackCmdArgs
    let shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }
        guard let window = target.windowOrNil else { return io.err(noWindowIsFocused) }
        guard let stack = window.parent as? TilingContainer, stack.orientation == .v else {
            return io.err("window-unstack currently works only for windows inside a stacked niri column")
        }
        guard let root = stack.parent as? TilingContainer, root.layout == .niri else {
            return io.err("window-unstack currently works only for windows inside a stacked niri column")
        }
        guard let rootIndex = stack.ownIndex else { return false }

        _ = window.unbindFromParent()
        window.bind(to: root, adaptiveWeight: WEIGHT_AUTO, index: rootIndex + 1)
        return true
    }
}
```

- [ ] **Step 3: Run the behavior tests**

Run: `swift test --filter WindowStackCommandTest`

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add Sources/AppBundle/command/impl/WindowStackCommand.swift Sources/AppBundle/command/impl/WindowUnstackCommand.swift
git commit -m "feat: add niri window stack and unstack commands"
```

### Task 5: Add failing hover-focus layout/config tests

**Files:**
- Modify: `Sources/AppBundleTests/command/NiriModeTest.swift`

- [ ] **Step 1: Add a failing viewport-anchor regression test**

```swift
func testHoverFocusDoesNotRecenterNiriViewport() async throws {
    config.defaultRootContainerLayout = .niri
    let workspace = Workspace.get(byName: name)
    let w1 = TestWindow.new(id: 1, parent: workspace.rootTilingContainer)
    let w2 = TestWindow.new(id: 2, parent: workspace.rootTilingContainer)
    TestWindow.new(id: 3, parent: workspace.rootTilingContainer)

    XCTAssertTrue(w2.focusWindow())
    try await workspace.layoutWorkspace()
    let before = w1.rectForTests?.topLeftX

    setFocus(to: LiveFocus(windowOrNil: w1, workspace: workspace))
    try await workspace.layoutWorkspace()

    assertEquals(w1.rectForTests?.topLeftX, before)
}
```

- [ ] **Step 2: Run the targeted test to verify it fails**

Run: `swift test --filter NiriModeTest/testHoverFocusDoesNotRecenterNiriViewport`

Expected: FAIL because any focus change currently recenters niri.

- [ ] **Step 3: Commit the failing regression test**

```bash
git add Sources/AppBundleTests/command/NiriModeTest.swift
git commit -m "test: cover hover focus viewport behavior in niri"
```

### Task 6: Implement hover-focus without recentering

**Files:**
- Modify: `Sources/AppBundle/focus.swift`
- Modify: `Sources/AppBundle/layout/layoutRecursive.swift`
- Modify: `Sources/AppBundle/GlobalObserver.swift`

- [ ] **Step 1: Add a small focus mode state in `focus.swift`**

```swift
@MainActor enum FocusTransitionMode {
    case normal
    case hoverWithoutRecentering
}

@MainActor private(set) var focusTransitionMode: FocusTransitionMode = .normal

@MainActor
func setFocus(to newFocus: LiveFocus, mode: FocusTransitionMode = .normal) -> Bool {
    focusTransitionMode = mode
    return setFocus(to: newFocus)
}
```

- [ ] **Step 2: Honor that state in niri viewport anchoring**

```swift
let anchorLeaf = (
    focusTransitionMode == .hoverWithoutRecentering
        ? workspace.mostRecentWindowRecursive ?? workspace.anyLeafWindowRecursive
        : (focus.workspace == workspace ? focus.windowOrNil : workspace.mostRecentWindowRecursive ?? workspace.anyLeafWindowRecursive)
) ?? mostRecentWindowRecursive ?? anyLeafWindowRecursive
```

- [ ] **Step 3: Add mouse-move hover handling in `GlobalObserver.swift`**

```swift
NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { _ in
    Task { @MainActor in
        guard config.niriMouseFollowsFocus else { return }
        guard currentlyManipulatedWithMouseWindowId == nil else { return }
        guard let token: RunSessionGuard = .isServerEnabled else { return }
        let workspace = mouseLocation.monitorApproximation.activeWorkspace
        let root = workspace.rootTilingContainer
        guard root.layout == .niri else { return }
        guard let hovered = mouseLocation.findIn(tree: root, virtual: false), hovered != focus.windowOrNil else { return }
        guard hovered.parent is TilingContainer else { return }

        _ = try await runLightSession(.globalObserver("mouseMoved"), token) {
            guard let live = hovered.toLiveFocusOrNil() else { return false }
            let changed = setFocus(to: live, mode: .hoverWithoutRecentering)
            if changed { hovered.nativeFocus() }
            return changed
        }
    }
}
```

- [ ] **Step 4: Run the targeted regression tests**

Run: `swift test --filter 'NiriModeTest/testHoverFocusDoesNotRecenterNiriViewport|ConfigTest/testParseNiriMouseFollowsFocus'`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/AppBundle/focus.swift Sources/AppBundle/layout/layoutRecursive.swift Sources/AppBundle/GlobalObserver.swift
git commit -m "feat: add niri hover focus without recentering"
```

### Task 7: Document bindings and config

**Files:**
- Modify: `README.md`
- Modify: `docs/config-examples/default-config.toml`

- [ ] **Step 1: Update README command/config docs**

```toml
    alt-rightSquareBracket = 'window-stack'
    alt-shift-rightSquareBracket = 'window-unstack'
```

```toml
niri-mouse-follows-focus = false
```

- [ ] **Step 2: Update the default config example**

```toml
# Hovering another tiled niri window updates focus/app activation but does not recenter.
niri-mouse-follows-focus = false

    alt-rightSquareBracket = 'window-stack'
    alt-shift-rightSquareBracket = 'window-unstack'
```

- [ ] **Step 3: Sanity-check docs text**

Run: `rg -n "window-stack|window-unstack|niri-mouse-follows-focus" README.md docs/config-examples/default-config.toml`

Expected: all three names appear in both places with consistent wording.

- [ ] **Step 4: Commit**

```bash
git add README.md docs/config-examples/default-config.toml
git commit -m "docs: document niri stack and hover focus"
```

### Task 8: Run focused verification and full relevant suite

**Files:**
- Test: `Sources/AppBundleTests/command/WindowStackCommandTest.swift`
- Test: `Sources/AppBundleTests/command/NiriModeTest.swift`
- Test: `Sources/AppBundleTests/config/ConfigTest.swift`

- [ ] **Step 1: Run the focused suites**

Run: `swift test --filter 'WindowStackCommandTest|NiriModeTest|ConfigTest'`

Expected: PASS.

- [ ] **Step 2: Run one broader command regression sweep**

Run: `swift test --filter 'JoinWithCommandTest|MoveCommandTest|CycleSizeCommandTest|FocusCommandTest'`

Expected: PASS.

- [ ] **Step 3: Record any failures and fix before claiming success**

```text
If a failure appears in command tree normalization, focus syncing, or config parsing, fix that code path before finalizing.
Do not mark the feature complete with red tests.
```

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: add niri stack commands and hover focus"
```

## Self-review

- Spec coverage: stack/unstack commands, config parsing, hover-focus semantics, non-recentering layout path, and docs all have explicit tasks.
- Placeholder scan: no TBD/TODO placeholders remain; every code-bearing step contains concrete files, commands, and sample code.
- Type consistency: command names, config key, and focus-mode naming are consistent across tasks.
