# AGENTS.md — Guidelines for AI Coding Agents

> **Project:** Sanctuary of the Wilds  
> **Engine:** Godot 4.3 Stable (Compatibility Renderer / WebGL 2.0)  
> **Platform:** Web (Vercel / GitHub Pages) & Linux Desktop  
> **Repository:** `https://github.com/blackpirateapps/sanctuary`

---

## ⚡ The Golden Agent Rule

Before concluding any task or turn, every agent **MUST**:
1. **Run the Project Verification Test:**
   ```bash
   godot --headless --path project --quit
   ```
   *Exit code must be 0 with zero fatal script or resource errors.*
2. **Update the Handoff Documentation:**
   * Record recent modifications, design choices, and test logs in [`handoff/LATEST_LOGS.md`](file:///home/dog/git/sanctuary/handoff/LATEST_LOGS.md).
3. **Commit and Push:**
   * Stage all changes, write a descriptive conventional commit, and push to `origin main`:
   ```bash
   git add .
   git commit -m "type(scope): description"
   git push origin main
   ```

---

## 🎨 Aesthetic & Engine Standards (*Dead Cells* Visual Rig)

1. **Strict Texel Density:**
   * The project viewport base is locked to **640×360** (16:9).
   * Texture filtering must remain set to `nearest` (filter mode 0) for crisp pixel art.
   * Never scale individual sprites arbitrarily; scale platforms and tiles to integer multiples.
2. **2D Normal-Mapped Lighting:**
   * Use `CanvasTexture` containing both diffuse and normal maps for interactive lights.
   * Pair with `PointLight2D` nodes using procedural light cookie textures (e.g. [`assets/props/light_cookie.png`](file:///home/dog/git/sanctuary/project/assets/props/light_cookie.png)).
3. **No Unicode Emojis in Text:**
   * Godot’s default font engine does NOT include an emoji fallback, rendering unicode symbols like `⚔️`, `🛡️`, `✦`, `📜` as missing-glyph hex boxes (`[26 94 FE 0F]`, `[27 26]`).
   * **Always use real pixel art sprites** from [`project/assets/ui/`](file:///home/dog/git/sanctuary/project/assets/ui) or clean text labels.
4. **Font Configuration:**
   * Global font is set to [`assets/fonts/golden-apple.ttf`](file:///home/dog/git/sanctuary/project/assets/fonts/golden-apple.ttf) via [`game_theme.tres`](file:///home/dog/git/sanctuary/project/assets/ui/game_theme.tres).
   * Antialiasing and subpixel positioning are disabled to maintain razor-sharp pixel edges.

---

## 📂 Codebase Directory Map

```
sanctuary/
├── AGENTS.md               # Agent guidelines and protocols (this file)
├── handoff/                # Comprehensive handover documentation
│   ├── README.md           # Handoff index
│   ├── ARCHITECTURE.md     # Technical and deployment architecture
│   ├── GAME_LOGIC.md       # Habit math, shields, and progression formulas
│   ├── FEATURES.md         # Deep-dive on features, controls, and UI
│   └── LATEST_LOGS.md      # Real-time logs, test results, and deployment URLs
├── project/                # Godot 4.3 project root
│   ├── project.godot       # Engine configuration & autoload registrations
│   ├── export_presets.cfg  # Web export settings (single-threaded WebAssembly)
│   ├── assets/             # Curated, optimized 2D pixel art assets
│   │   ├── characters/     # Player ninja & Evil Wizard animation frames
│   │   ├── environment/    # 4-layer parallax backgrounds & tilesets
│   │   ├── fonts/          # Golden Apple & Earth Illusion pixel fonts
│   │   ├── props/          # Normal-mapped lit braziers & light cookies
│   │   ├── ui/             # Dedicated 16x16 pixel icons (shield, crystal, scroll, sword)
│   │   └── vfx/            # Arcane runes, starburst impacts, holy rays
│   ├── scenes/             # Game scenes & UI modals (.tscn)
│   └── scripts/            # Autoload singletons & controller scripts (.gd)
├── export/                 # Target folder for web export builds (.html, .wasm, .pck)
├── .github/workflows/      # Automated Godot Web export CI/CD pipeline
└── vercel.json             # Vercel routing and WebAssembly COOP/COEP headers
```

---

## 🛠 Web & Cloud Deployment Rules

* **Single-Threaded Web Export:**
  * `variant/thread_support=false` is enforced in [`export_presets.cfg`](file:///home/dog/git/sanctuary/project/export_presets.cfg).
  * This guarantees instant compatibility on mobile Safari, iOS, Chrome, and Firefox without requiring `SharedArrayBuffer` threading locks.
* **Vercel Hosting:**
  * Configured in [`vercel.json`](file:///home/dog/git/sanctuary/vercel.json) targeting `outputDirectory: "export"`.
  * Headers `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` are pre-set.
* **Persistence Across Sessions:**
  * [`HabitManager.gd`](file:///home/dog/git/sanctuary/project/scripts/habit_manager.gd) uses `JavaScriptBridge.eval()` to read/write `window.localStorage` on Web, and falls back to `user://habit_save.json` on desktop. Never bypass this abstraction.
