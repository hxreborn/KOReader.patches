# KOReader.patches

Userpatches for KOReader.

## Installation

Drop the `.lua` file(s) into your device's `koreader/patches/` directory and restart KOReader. See the upstream guide: <https://github.com/koreader/koreader/wiki/User-patches>.

## Compatibility

- Minimum KOReader version: see each patch header
- Last tested build: `v2025.10-81-g4186cde33_2026-01-06`

## Patches

| Patch | Description | Min version |
|-------|-------------|-------------|
| `2-footer-zones.lua` | Adds "Dynamic" alignment that distributes status-bar items across left / center / right zones | v2025.04-52 |

## 2-footer-zones.lua

Adds a fourth alignment option, **Dynamic**, alongside Left / Center / Right under *Status bar → Configure items → Alignment*. With Dynamic selected, the enabled status-bar items spread evenly across three zones:

- 1 item → center
- 2 items → left + right
- 3 items → left + center + right
- 4+ items → `floor(n/3)` on each side, the remainder in center

Behaviour notes:

- Skips silently when the progress bar is set to `alongside` (no zone layout in that mode)
- Respects the `Items separator` setting (vbar / bullet / dot / none) via `genSeparator()`
- Preserves merge-flag joins for items that combine, like custom text combos
- Honours `compact_items` by substituting hair-spaces inside individual item text
- Locates the alignment menu by behaviour-probing each radio's `checked_func`, so locale changes and upstream label edits don't break it

## Optional integration

The patch tries to load `patches/guard.lua` (from [sebdelsol/KOReader.patches](https://github.com/sebdelsol/KOReader.patches)) for version gating. If `guard.lua` is present, the patch refuses to run on KOReader builds older than the declared minimum. If it's absent, the patch loads anyway and skips the version gate — the call is wrapped in `pcall`.

## License

GPL-3.0. See [LICENSE](LICENSE).
