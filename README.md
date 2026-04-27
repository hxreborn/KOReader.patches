# KOReader.patches

Personal userpatches for KOReader. 

## Install

Copy `.lua` files into `koreader/patches/` and restart KOReader. See the upstream [user-patches guide](https://github.com/koreader/koreader/wiki/User-patches).

## 2-footer-zones.lua

Adds Dynamic to Status bar → Configure items → Alignment*. Splits enabled items across left, center, right. 1 item centers; 2 items split L/R; 3+ spread evenly with leftovers in center.

<p align="center"><img src="assets/menu-dynamic.png" width="380" alt="Dynamic option in alignment menu"></p>

<p><code>n = 1</code> (same as center)</p>

![1 item](assets/dynamic-1.png)

<p><code>n = 2</code></p>

![2 items](assets/dynamic-2.png)

<p><code>n = 3</code></p>

![3 items](assets/dynamic-3.png)

<p><code>n = 4</code></p>

![4 items](assets/dynamic-4.png)

<p><code>n = 5</code></p>

![5 items](assets/dynamic-5.png)

<p><code>n = 6</code></p>

![6 items](assets/dynamic-6.png)


> [!NOTE]
> Progress bar must be above/below items (not alongside).

Min KOReader: `v2025.04-52`. Tested on `v2025.10-81-g4186cde33_2026-01-06`.

## License

[GPL-3.0](LICENSE).
