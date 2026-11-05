# Sanctuary of the Wilds

> A 2D pixel art habit-tracking ecosystem simulator inspired by *Dead Cells*, built with Godot 4 and targeted for Web browsers.

---

## 🌿 Core Concept

In **Sanctuary of the Wilds**, you awaken in a blighted, corrupted forest valley. The valley’s health is directly tethered to your real-life discipline and abstinence from compulsive habits:

- **Clean Time = Restoration:** As hours and days elapse without relapse, the corruption dissipates. Sickly thorny vines wither and give way to ancient bioluminescent flora, crystal springs, and wandering spirit beasts.
- **Urge Defense ("Sanctuary Under Siege"):** When an urge or temptation hits in real life, triggering the emergency button starts an immediate mini-trial—engaging your brain with high-focus gameplay and real-world physical grounding to divert the craving.
- **Resilient Progression:** No punishing full-resets. Relapses incur a "Blight Storm" that damages outer shrines or wilts temporary blooms, but deep root systems, unlocked lore, and awakened spirit beasts endure.

---

## 🎨 Visual Identity (*Dead Cells* Style)

- **Palette Dynamics:** Dramatic contrast between high-saturation neon greens/cyan bioluminescence and oppressive violet/charcoal corruption.
- **Lighting & Atmospherics:** Normal-mapped 2D sprites, dynamic point lights, glowing flora, and multi-layered particle fog.
- **Multi-layer Parallax:** 5+ layers of depth with subtle atmospheric haze.

---

## 🛠 Tech Stack & Web Deployment

- **Engine:** Godot Engine 4.x (Compatibility Renderer / WebGL 2.0).
- **Target Platform:** Web (HTML5 / WebAssembly).
- **Hosting:** Vercel (configured with `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` headers for high-performance WebAssembly).
- **Storage:** LocalStorage & IndexedDB (offline-first persistence).

---

## 📁 Repository Structure

```
sanctuary/
├── .github/workflows/    # CI/CD pipelines (Godot export & deployment)
├── project/              # Godot 4 project source directory
│   ├── assets/           # Sprites, tilesets, SFX, music
│   ├── scenes/           # UI, Sanctuary, Minigames
│   ├── scripts/          # State machines, habit tracking, time calculations
│   └── project.godot     # Godot project configuration
├── export/               # Web build outputs for Vercel
├── vercel.json           # Vercel deployment headers & routing config
└── README.md
```
