# Architecture & Technical Documentation

## 1. Engine & Rendering Architecture

* **Engine:** Godot Engine 4.3 Stable (`4.3.stable.official.77dcf97d8`).
* **Renderer:** `gl_compatibility` (OpenGL ES 3.0 / WebGL 2.0).
* **Base Resolution:** 640×360 Viewport with `keep` aspect ratio and `viewport` stretch mode, window override 1280×720.
* **Pixel Filter:** `nearest` (filter mode 0) globally enforced for pixel art sharpness.

---

## 2. The 2D Dynamic Lighting Pipeline

Inspired by the visual techniques of *Dead Cells*, the game pairs real-time lighting with normal maps on flat 2D pixel art:

1. **Ambient World Lighting:**
   * Handled by a `DirectionalLight2D` in [`main.tscn`](file:///home/dog/git/sanctuary/project/scenes/main.tscn).
   * Color is dynamically computed in [`SanctuaryState.gd`](file:///home/dog/git/sanctuary/project/scripts/sanctuary_state.gd) based on active blight/corruption level (interpolating between deep necrotic purple `#1e122b` and flourishing golden-emerald dawn `#385e4c`).
2. **Normal-Mapped Light Emitters (Braziers):**
   * Implemented in [`brazier.gd`](file:///home/dog/git/sanctuary/project/scripts/brazier.gd).
   * Uses a Godot `CanvasTexture` assigning:
     * `diffuse_texture`: [`assets/props/dungeon/brazier-orange_32px_scroller_outline_lit.png`](file:///home/dog/git/sanctuary/project/assets/props/dungeon/brazier-orange_32px_scroller_outline_lit.png)
     * `normal_texture`: [`assets/props/dungeon/brazier-orange_32px_scroller_normal.png`](file:///home/dog/git/sanctuary/project/assets/props/dungeon/brazier-orange_32px_scroller_normal.png)
   * The sprite uses `hframes = 6` to animate the 6-frame flame loop while calculating surface normal reflections.
   * `PointLight2D` uses an organic multi-frequency sine wave to simulate organic flame flickering.
3. **Player Lantern Aura:**
   * A subtle cyan/radiant `PointLight2D` attached to the player with gentle breathing oscillation.

---

## 3. Web & Browser Integration

* **Single-Threaded WebAssembly:**
  * Enabled via `variant/thread_support=false` in [`export_presets.cfg`](file:///home/dog/git/sanctuary/project/export_presets.cfg).
  * Eliminates the requirement for cross-origin isolation on platforms that don't support `SharedArrayBuffer` (e.g. mobile Safari).
* **Vercel Headers:**
  * In [`vercel.json`](file:///home/dog/git/sanctuary/vercel.json):
    ```json
    {
      "outputDirectory": "export",
      "cleanUrls": true,
      "headers": [
        {
          "source": "/(.*)",
          "headers": [
            { "key": "Cross-Origin-Opener-Policy", "value": "same-origin" },
            { "key": "Cross-Origin-Embedder-Policy", "value": "require-corp" },
            { "key": "Access-Control-Allow-Origin", "value": "*" }
          ]
        }
      ]
    }
    ```
* **Persistence Bridge:**
  * Web environment uses `JavaScriptBridge.eval()` to sync state to browser `window.localStorage`.
  * Desktop fallback saves to `user://habit_save.json`.

---

## 4. CI/CD Build Pipeline

* **Workflow:** [`.github/workflows/deploy.yml`](file:///home/dog/git/sanctuary/.github/workflows/deploy.yml)
* **Runner Image:** `barichello/godot-ci:4.3`
* **Build Sequence:**
  1. Check out repository.
  2. Set up export templates in `~/.local/share/godot/export_templates/4.3.stable`.
  3. Pre-import all raw assets via headless editor: `godot --headless --path project --editor --quit`.
  4. Export to Web using absolute workspace target: `godot --headless --path project --export-release "Web" "$EXPORT_DIR/index.html"`.
  5. Deploy artifacts to GitHub Pages and upload build artifacts for Vercel.
