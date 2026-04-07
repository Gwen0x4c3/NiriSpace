# Niri stack/unstack and hover-focus design

## Scope

Add two niri-oriented window-management commands and one niri-scoped focus behavior config:

1. `window-stack` stacks the focused window onto its left neighbour, producing a shared vertical column.
2. `window-unstack` removes the focused window from a stacked niri column and gives it its own top-level niri column.
3. `niri-mouse-follows-focus` makes hover over another tiled niri window update focus and native app activation without recentering the niri viewport. A normal click still follows the existing native-focus path and recenters the clicked window.

## Why this shape

The existing codebase already has the right primitives:

- `join-with` can group siblings into a nested tiling container.
- niri centering is currently derived from `focus` in `layoutRecursive.swift`.
- mouse clicks already flow through native focus detection, then sync back into the internal focus cache.

The smallest safe extension is therefore:

- add dedicated commands for stack/unstack rather than special-casing `move`/`join-with`
- keep hover-follow-focus opt-in and scoped to `niri`
- separate logical focus updates from viewport recentering for hover-driven focus changes

## Command behavior

### `window-stack`

- Works only when the focused window belongs to a niri root container.
- Targets the focused window's immediate left sibling column at the niri root level.
- Creates or reuses a vertical tiling container for that left column.
- Inserts the focused window into that vertical container.
- Fails with a clear error when there is no left neighbour or the focused window is not in niri.

Example:

- before: `.niri([.window(1), .window(2), .window(3)])` with focus on `3`
- after:  `.niri([.window(1), .v_tiles([.window(2), .window(3)])])`

### `window-unstack`

- Works only when the focused window belongs to a stacked column inside a niri root container.
- The focused window must not already be a direct niri column.
- Removes the focused window from its vertical stack and reinserts it as a direct niri column immediately to the right of the original stacked column.
- Preserves the current focus on the same window.
- Fails with a clear error when the window is not in a stacked niri column.

Example:

- before: `.niri([.window(1), .v_tiles([.window(2), .window(3)])])` with focus on `3`
- after:  `.niri([.window(1), .v_tiles([.window(2)]), .window(3)])`
- normalization then keeps the single-child nested container intact because it is still a direct niri column.

## Hover-focus behavior

### Config

- New config key: `niri-mouse-follows-focus = false`
- Applies only in niri layout.
- Applies only to tiled windows, not floating windows, popup windows, or desktop/background regions.

### Hover semantics

- When the mouse enters another tiled niri window, update internal focus and native macOS focus to that window/app.
- Do not move the mouse.
- Do not change tree structure.
- Do not recenter the niri viewport on hover.

### Click semantics

- Click behavior stays on the existing native-focus path.
- Because normal niri layout already centers based on the current focus, clicking a different tiled niri window keeps the existing "clicked window becomes centered" behavior.

## Architecture changes

### 1. Explicit hover-focus reason

Add a small focus-mode flag that lets layout code distinguish:

- normal focus changes -> may recenter niri
- hover-driven focus changes -> must not recenter niri

`setFocus` remains the single source of truth, but hover-triggered callers set a temporary "suppress niri recenter" state before layout.

### 2. Global mouse move monitor

Extend the global event observer with a mouse-move monitor that:

- ignores work when the feature flag is off
- ignores motion while a window is being moved/resized with mouse
- hit-tests the window under the pointer
- if it is a different tiled niri window, runs a light session to sync focus and native activation without recentering

### 3. Dedicated commands

Add `window-stack` and `window-unstack` as first-class commands so bindings and docs can expose them cleanly.

## Testing

Add unit tests for:

- parsing of `window-stack` and `window-unstack`
- stacking in niri
- unstacking from a niri vertical column
- failure cases for non-niri and missing left neighbour
- config parsing of `niri-mouse-follows-focus`
- a focused layout test proving hover-suppressed focus does not change the niri viewport anchor

## Out of scope

- stacking onto right/up/down neighbours
- hover-follow-focus outside niri
- changing floating-window behavior
- moving or warping the pointer on hover
