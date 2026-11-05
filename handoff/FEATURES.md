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

* **World Scale & Biome Journey:**
  * Total reachable world width: **5,760 px** (9 screen-widths, 16:9 640×360 viewport base).
  * **Sanctuary Forest (`x = 0..950`):** Ancient sacred ground, lush stone platforms, amber braziers, and the Sacred Altar.
  * **Transition Mire (`x = 950..1650`):** Dynamic S-curve smoothstep crossfade between Forest and Swamp parallax layers and ambient lighting.
  * **Zone 1: Murky Outskirts (`x = 1650..2700`):** Modular ridges, gnarled swamp trees, weeping willows, and the Corrupted Monolith (`[B] Urge Trial`).
  * **Zone 2: Sunken Canopy & Stilt Walkways (`x = 2700..4200`):** Tall ridges (Ridges 4 & 6), multi-tier wooden plank platforms, ladders, waving tattered banners (`Flag.png`), collectible Spirit Coins, and the interactive Corrupted Cache chest (`[E]`).
  * **Zone 3: Abyssal Heart & Void Sanctum (`x = 4200..5760`):** Deep mist dispersion (`SwampMistParticles`), ancient sunken megaliths, dense thorny thickets (bushes & grass), and the Abyssal Relic Altar (`[E] Commune with Void Relic`).
* **Parallax Sky & Forest:**
  * 4 forest layers + 5 corrupted swamp layers with seamless horizontal mirroring (`Vector2(640, 0)`).
* **Lit Braziers (13 Total):**
  * Animated 6-frame flame cycle (`hframes = 6`) with real-time normal maps.
  * 4 Warm Amber braziers in the sanctuary + 9 Violet/Spectral braziers (`Color(0.72, 0.35, 0.95, 1)`) lighting the pathway deeper into the mire.
* **Landmarks & Interactive Objects:**
  * **The Sacred Altar (`x = 640, y = 312`):** Purifies 5% blight for 30 Focus Mana (`[E]`).
  * **The Corrupted Monolith (`x = 2500, y = 312`):** Triggers the panic button Urge Defense Trial (`[B]`).
  * **The Corrupted Cache Chest (`x = 3580, y = 235`):** Interactive 4-frame animated chest awarding +35 Focus Mana with gold/violet particle explosion (`[E]`).
  * **Spirit Coins (6 Perches):** 4-frame spinning coins granting +5 Focus Mana on touch.
  * **The Abyssal Relic Altar (`x = 5250, y = 312`):** Ancient void altar for deep meditation (`[E]`), triggering parry stance, cleansing 5% blight, and granting +25 Focus Mana.
* **Interactive Wildlife Ecosystem:**
  * 19 fauna instances inhabiting all 9 screen-widths of the 5,760px world.
  * **Hybrid Visual Rig:** Multi-frame animated characters (Cute Pack: Bees, Dragonflies, Bats, White Bats, Guardian Bear, Celestial Drake) paired with crisp 32×32 fauna (Tiny Animals: Deer, Doe, Rabbits, Foxes, Hedgehogs, Frogs, Snails, Owls, Ravens).
  * **Locomotion State Machine:** Parabolic ground hopping physics, smooth walking cycles, perched branch idling with head-turns/wing stretches, and sinusoidal flying/hovering.
  * **Reactive Behaviors:** Running near shy creatures (rabbits, songbirds) prompts reactive fleeing or taking flight into the canopy.
  * **Gentle Petting Mechanics:** Approaching peacefully activates `[E] Pet [Creature]`, triggering pixel heart/sparkle particles (`CPUParticles2D`), joyful bounce tweens, narrative reflection text, and a +2.0 Focus Mana reward.
  * **Habit Milestone Spirit Unlocks:**
    * *Tier 1 (1 hr+ / First Sprout):* Golden Spirit Doe awakens near the Sacred Altar with celestial light.
    * *Tier 3 (24 hrs+ / Ancient Hearth):* Ancient Guardian Bear emerges at the forest edge ($x=1050$).
    * *Tier 5 (7 days+ / Eternal Citadel):* Mythical Celestial Drake awakens beside the Abyssal Relic ($x=5220$).

* **Atmospheric Particles:**
  * Forest Celestial Spores (`x = 640`, 45 continuous drifting particles).
  * Swamp Blight Mist (`x = 3700`, 120 drifting violet mist particles spanning 4,300px).

---

## 3. UI HUD & Modals

* **Top Bar:**
  * **Streak Gauge:** Displays clean time formatted as `00d : 00h : 00m : 00s`.
  * **Valley Blight Progress Bar:** Smooth pink/purple progress bar indicating remaining blight percentage.
  * **Aegis Shields:** Dedicated heater shield icon ([`shield_icon.png`](file:///home/dog/git/sanctuary/project/assets/ui/shield_icon.png)) showing active shield count (`1/3`, `2/3`, `BROKEN`).
  * **Focus Mana / Coins:** Golden crystal icon ([`focus_icon.png`](file:///home/dog/git/sanctuary/project/assets/ui/focus_icon.png)) displaying real-time balance with 2 decimal points (`0.00`), actively ticking upward by the second as coins accumulate via tiered milestone multipliers.
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
