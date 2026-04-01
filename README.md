# NiriSpace

**Niri-style scrollable tiling window manager for macOS, built on top of [AeroSpace](https://github.com/nikitabobko/AeroSpace).**

NiriSpace brings [Niri](https://github.com/YaLTeR/niri)'s innovative scrollable tiling layout to macOS. Instead of traditional i3-style fixed grid tiling, windows are arranged in an infinitely scrollable strip — each window is a column that you can scroll through horizontally, resize dynamically, and cycle through predefined sizes.

## Key Features

- **Niri scrollable tiling layout** — Windows are arranged as columns in a horizontally scrollable strip, just like [Niri](https://github.com/YaLTeR/niri) on Wayland
- **`cycle-size` command** — Cycle the focused window through predefined column widths (e.g. `33%`, `50%`, `66%`, `80%`)
- **`niri-default-column-width-percent`** — Configure the default column width for new windows in niri layout
- **Focused window border** — Draw a visible border around the focused window for easy identification
- All existing AeroSpace features: tree-based tiling, fast workspace switching, plain text config, CLI-first, multi-monitor support, no SIP required

## Configuration

### Niri Layout Options

```toml
# Use niri as the default layout for all workspaces
# Possible values: tiles | accordion | niri
default-root-container-layout = 'niri'

# Default column width for new windows in niri layout (percent of monitor width)
niri-default-column-width-percent = 80

# Draw a border around the focused window
focused-window-border-enabled = true
focused-window-border-width = 4
```

### Niri Key Bindings Example

```toml
[mode.main.binding]
    # Cycle focused window through predefined column widths
    alt-r = 'cycle-size 33% 50% 66% 80%'

    # Focus navigation (scrolls through the column strip in niri layout)
    alt-h = 'focus left'
    alt-j = 'focus down'
    alt-k = 'focus up'
    alt-l = 'focus right'

    # Move windows within the strip
    alt-shift-h = 'move left'
    alt-shift-j = 'move down'
    alt-shift-k = 'move up'
    alt-shift-l = 'move right'

    # Resize
    alt-minus = 'resize smart -50'
    alt-equal = 'resize smart +50'
```

### New Commands

| Command | Description |
|---|---|
| `cycle-size <sizes...>` | Cycle the focused column through a list of predefined widths. Sizes are specified as percentages (e.g. `33%`, `50%`, `66%`). |

### New Config Options

| Option | Default | Description |
|---|---|---|
| `default-root-container-layout` | `'tiles'` | Root container layout. Now accepts `'niri'` in addition to `'tiles'` and `'accordion'`. |
| `niri-default-column-width-percent` | `80` | Default column width (as % of monitor width) for new windows in niri layout. |
| `focused-window-border-enabled` | `false` | Whether to draw a border around the focused window. |
| `focused-window-border-width` | `4` | Width of the focused window border in pixels. |

## Installation

### From GitHub Releases

Download the latest release from [Releases](../../releases), unzip, and move `NiriSpace.app` to `/Applications`.

On first launch, macOS may block the app. Go to **System Settings > Privacy & Security** and click **Open Anyway**.

### Build from Source

```bash
git clone https://github.com/user/NiriSpace.git
cd NiriSpace
./build-release.sh --codesign-identity -
./install-from-sources.sh --dont-rebuild
```

## How Niri Layout Works

In traditional tiling (i3/AeroSpace `tiles` mode), the screen is divided into a fixed grid and every window shares screen real estate. When you have many windows, each one gets tiny.

In **niri layout**, windows are arranged as **columns in an infinite horizontal strip**:

```
  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
  │         │ │         │ │ focused │ │         │
  │  win 1  │ │  win 2  │ │  win 3  │ │  win 4  │
  │         │ │         │ │         │ │         │
  └─────────┘ └─────────┘ └─────────┘ └─────────┘
              ◄── scrollable strip ──►
```

- Each window gets a full-height column with a configurable width
- The viewport scrolls to keep the focused window visible
- `cycle-size` lets you quickly toggle a window between different widths (e.g. narrow reference pane vs. wide editor)

## Acknowledgements

NiriSpace is a fork of **[AeroSpace](https://github.com/nikitabobko/AeroSpace)** by [Nikita Bobko](https://github.com/nikitabobko).
AeroSpace is the foundation that makes NiriSpace possible — its tree-based tiling engine, workspace emulation, CLI architecture, and accessibility API integration are all inherited from AeroSpace.
A huge thanks to Nikita and the AeroSpace contributors for building such a solid and extensible window manager.

The niri scrollable tiling paradigm is inspired by **[Niri](https://github.com/YaLTeR/niri)** by Ivan Molodetskikh.

## Development

See [dev-docs/development.md](./dev-docs/development.md) for build instructions and development notes.

## License

MIT — see [LICENSE.txt](./LICENSE.txt)
