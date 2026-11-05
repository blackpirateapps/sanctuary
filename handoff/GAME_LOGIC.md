# Game Logic & Habit Mechanics

The game systems are specifically architected around behavioral psychology to eliminate the *"what-the-hell"* binge effect common in standard streak trackers.

---

## 1. Chronos Engine (`HabitManager.gd`)

### Time Tracking & Offline Progression
* **Epoch Timestamps:** Rather than running simple timers, the game stores `start_epoch` and `last_checkin_epoch` (Unix seconds).
* **Elapsed Time:**
  $$\Delta t_{\text{clean}} = \max(0, \text{current\_unix\_time} - \text{start\_epoch})$$
  $$\text{Days} = \frac{\Delta t_{\text{clean}}}{86400}, \quad \text{Hours} = \lfloor \frac{\Delta t_{\text{clean}}}{3600} \rfloor \pmod{24}$$
* **Passive Focus Mana / Coin Generation (Tiered Milestone Acceleration):**
  Generation rate starts at **10.0 coins/hr** ($\approx 0.0028 \text{ coins/sec}$) and accelerates across clean streak milestone tiers:

  | Tier | Streak Duration | Multiplier | Generation Rate | Coins Generated in Bracket |
  | :--- | :--- | :---: | :--- | :--- |
  | **Tier 1: Ember Foundation** | $0 \le t < 1\text{ hr}$ | **$1.0\times$** | $10.0\text{ coins/hr}$ ($0.0028/\text{s}$) | $10.00$ coins |
  | **Tier 2: First Sprout** | $1 \le t < 6\text{ hrs}$ | **$1.5\times$** | $15.0\text{ coins/hr}$ ($0.0042/\text{s}$) | $75.00$ coins |
  | **Tier 3: Crystal Stream** | $6 \le t < 24\text{ hrs}$ | **$2.5\times$** | $25.0\text{ coins/hr}$ ($0.0069/\text{s}$) | $450.00$ coins |
  | **Tier 4: Ancient Hearth** | $24 \le t < 72\text{ hrs}$ ($1\text{--}3\text{ d}$) | **$4.0\times$** | $40.0\text{ coins/hr}$ ($0.0111/\text{s}$) | $1,920.00$ coins |
  | **Tier 5: Grove Sanctuary** | $72 \le t < 168\text{ hrs}$ ($3\text{--}7\text{ d}$) | **$5.0\times$** | $50.0\text{ coins/hr}$ ($0.0139/\text{s}$) | $4,800.00$ coins |
  | **Tier 6: Eternal Citadel** | $t \ge 168\text{ hrs}$ ($7+\text{ d}$) | **$6.0\times$** *(Cap)*| $60.0\text{ coins/hr}$ ($0.0167/\text{s}$) | Compounding at maximum rate |

* **Continuous Live Generation:**
  $$\Delta \text{coins} = \left(\frac{10.0 \times \text{Multiplier}(t)}{3600}\right) \times \Delta t$$
  Emits `mana_changed` on `_process` allowing HUD live updates with two decimal places.

* **Piecewise Offline Catch-Up Integration:**
  When loading the game after being offline across the interval $[t_{\text{last}}, t_{\text{now}}]$, coins are integrated accurately across each tier slice:
  $$\text{Coins Earned} = \sum_{k} \Delta t_k \times \text{Rate}_k$$
  where $\Delta t_k$ is the overlap duration within Tier $k$.

### Aegis Grace Shields (Setback Protection)
* **The Problem:** Harsh permadeath resets (0 days on relapse) trigger feelings of helplessness, causing players to abandon tracking and binge.
* **The Solution:**
  * Players start with **1 Aegis Shield** (maximum 3).
  * Every 3 successful Urge Trials awards an additional shield.
  * **When a slip is logged:**
    * If `shields > 0`: The shield absorbs the setback. `shields -= 1`. **The clean streak is NOT reset to 0.** The valley experiences a temporary Blight Surge (+10% corruption), but the core progress stands.
    * If `shields == 0`: The streak timer resets, but all historical records, awakened shrines, and meta-progress remain. The player is immediately granted 1 fresh shield to assist their new foundation.

---

## 2. Valley Corruption & Terraforming (`SanctuaryState.gd`)

* **Corruption Percentage:**
  $$C(d) = \text{clamp}(85.0 - (d \times 2.8), 0.0, 100.0)$$
  where $d$ is clean days.
  * At 0 clean days: Valley is 85% blighted.
  * At 14 clean days: Valley is ~45% blighted.
  * At 30 clean days: Valley is 0% blighted (fully purified).
* **Shrine Channeling:**
  * Players can stand near the sacred shrine and press `[E]` to spend 30 Focus Mana.
  * Channeling immediately cleanses 5% of valley blight and triggers a celestial light pulse.
* **Milestones System:**
  * `0.04 days (~1h)`: First Sprout (Life stirs in the ashen soil)
  * `1.0 day`: Crystal Springs (Clean water flows again)
  * `3.0 days`: Guardian Altar (Ancient stone hearth awakens)
  * `7.0 days`: Sacred Grove (Canopy spreads, spirits return)
  * `14.0 days`: Ethereal Citadel (Blight banished from the valley)
  * `30.0 days`: Eternal Sanctuary (Mastery of self and spirit)

---

## 3. The Urge Interceptor ("Sanctuary Under Siege")

When a craving hits in real life, the player triggers the Urge Trial (`[B]` or on-screen button). This is an active, structured psychological intervention:

```
[ Urge Triggered ]
       │
       ▼
[ Phase 1: High-Focus Combat (20s) ]
• Evil Wizard channels void runes
• 12 Arcane Void Runes spawn dynamically
• Rapid-fire clicking/tapping replaces craving dopamine
       │
       ▼
[ Phase 2: Somatic Recalibration (16s) ]
• Visual breathing circle guides 4-4-4 box breathing:
  - Inhale with rising light (4s)
  - Hold focus (4s)
  - Slow exhale and let go (4s)
• Somatic anchor prompt ("Take a sip of water...")
       │
       ▼
[ Phase 3: Victory & Reward ]
• +50 Focus Mana awarded
• Valley Blight cleansed by 3%
• Progress toward earning next Aegis Shield
```
