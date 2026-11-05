# Sanctuary of the Wilds — Agent Handoff Documentation

Welcome, incoming agent. This directory contains complete architectural, algorithmic, and feature documentation for **Sanctuary of the Wilds**.

---

## 📑 Handoff Documentation Index

1. **[ARCHITECTURE.md](file:///home/dog/git/sanctuary/handoff/ARCHITECTURE.md)**
   * Engine version, rendering configuration, WebAssembly build pipeline, CI/CD automated deployment, and file hierarchy.
2. **[GAME_LOGIC.md](file:///home/dog/git/sanctuary/handoff/GAME_LOGIC.md)**
   * Mathematical formulas for habit streak tracking, offline $\Delta t$ delta calculation, Aegis Grace Shield mechanics, valley corruption percentages, and the two-phase Urge Interceptor protocol.
3. **[FEATURES.md](file:///home/dog/git/sanctuary/handoff/FEATURES.md)**
   * Full feature inventory: Player physics controller, input mappings, normal-mapped 2D lighting rig, UI HUD, accountability modals, and Chronicles progress log.
4. **[LATEST_LOGS.md](file:///home/dog/git/sanctuary/handoff/LATEST_LOGS.md)**
   * Most recent test verification output, commit hashes, live web deployment URLs, and pending backlog tasks.

---

## 📌 Quick Commands for Agents

* **Run Verification Test:**
  ```bash
  godot --headless --path project --quit
  ```
* **Run Local Game Preview:**
  ```bash
  godot --path project
  ```
* **Trigger Web Export Locally (if templates installed):**
  ```bash
  godot --headless --path project --export-release "Web" ../export/index.html
  ```
