# Features, Controls & UI Documentation

## 1. Input & Controls

| Action | Keybinding | Alternate Input | Description |
| :--- | :--- | :--- | :--- |
| **Move Left / Right** | `A` / `D` | `Left` / `Right` Arrow | Responsive horizontal movement with instant turnaround. |
| **Jump** | `Space` | `W` / `Up` Arrow | Platformer jump with gravity scaling. |
| **Attack Combo** | `J` | Left Mouse Click | 3-hit animated ninja strike combo. |
| **Defend / Meditate** | `K` | Right Mouse Click | Defensive parry stance with energy shield flare. |
| **Channel Shrine** | `E` | — | Spend 30 Focus Mana at the central altar to purify blight. |
| **Urge Defense Trial** | `B` | On-Screen Button | Immediately opens the emergency "Sanctuary Under Siege" trial. |
| **Chronicles Modal** | `C` | On-Screen Button | Opens the milestone and record reflection log. |

---

## 2. World & Environmental Visuals

* **Parallax Sky & Forest:**
  * 4 distinct layers: `BG-1` (Sky gradient), `BG-2` (Distant mountains), `BG-3` (Midground forest canopy), and `BG-4` (Foreground mist).
  * Seamless horizontal mirroring (`Vector2(640, 0)`).
* **Lit Braziers:**
  * Animated 6-frame flame cycle (`hframes = 6`) with real-time normal maps.
  * Multi-frequency light flicker interacting with stone platforms.
* **Floating Spores (`CPUParticles2D`):**
  * 45 continuous ambient particles drifting upward across the valley.
* **The Sacred Altar:**
  * Located at `(640, 295)`.
  * Emits an emerald/celestial light that grows in intensity as clean days accumulate.

---

## 3. UI HUD & Modals

* **Top Bar:**
  * **Streak Gauge:** Displays clean time formatted as `00d : 00h : 00m : 00s`.
  * **Valley Blight Progress Bar:** Smooth pink/purple progress bar indicating remaining blight percentage.
  * **Aegis Shields:** Dedicated heater shield icon ([`shield_icon.png`](file:///home/dog/git/sanctuary/project/assets/ui/shield_icon.png)) showing active shield count (`1/3`, `2/3`, `BROKEN`).
  * **Focus Mana:** Golden crystal icon ([`focus_icon.png`](file:///home/dog/git/sanctuary/project/assets/ui/focus_icon.png)) with live balance.
  * **Log Slip Button:** Opens the non-punitive accountability dialog.
* **Bottom Bar:**
  * **Chronicles Button:** Styled parchment button with scroll icon ([`scroll_icon.png`](file:///home/dog/git/sanctuary/project/assets/ui/scroll_icon.png)).
  * **Defend Sanctuary Button:** Crusader sword icon ([`sword_icon.png`](file:///home/dog/git/sanctuary/project/assets/ui/sword_icon.png)) with golden action styling.
* **Urge Trial Modal ([`urge_trial.tscn`](file:///home/dog/git/sanctuary/project/scenes/urge_trial.tscn)):**
  * Dimmed vignette overlay.
  * Animated Evil Wizard sprite channeling void runes.
  * Interactive clicking runes with bright impact starburst animations.
  * Somatic pulsing circle for breath pacing.
* **Accountability Modal ([`slip_modal.tscn`](file:///home/dog/git/sanctuary/project/scenes/slip_modal.tscn)):**
  * Explains how shields protect the streak and provides compassionate reframing.
* **Chronicles Modal ([`chronicles_modal.tscn`](file:///home/dog/git/sanctuary/project/scenes/chronicles_modal.tscn)):**
  * Historical record of best clean streak and total urges repelled.
  * Scrollable list of locked vs. active milestones.
