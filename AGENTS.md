# Roblox Fishing development rules

Use Studio's built-in MCP; no Rojo. Read docs/PLAN.md and docs/STATE.md first.

## Ownership and editability
- world/fishing.rbxl is the saved playable place and authoritative manually edited scene.
- tools/world/bootstrap.luau is an explicit Edit-only authoring/migration tool, NEVER a runtime Script.
- src/ contains versioned gameplay sources deployed explicitly; no automatic two-way sync.
- Owned roots: Workspace.FishingWorld, ReplicatedStorage.FishingRemotes, ServerScriptService.FishingServer, StarterPlayer.StarterPlayerScripts.FishingClient, StarterPack.FishingRod; project-named Fishing* Lighting effects.
- Permanent scenery, water, shops and piers MUST exist in Edit and be selectable/movable. Only transient gameplay visuals spawn at runtime.
- Never delete/recreate FishingWorld on refresh. Preserve transforms, manual children and edits. Add missing named objects or perform explicit one-time versioned migrations.
- Gameplay reads each Water part's current transform, never hardcoded world coordinates.
- Do not clear user Terrain. Back up the place before migrations.

## Workflow
1. Verify exact Studio window and Edit mode.
2. Save source changes first. Run authoring only in Edit; deploy gameplay separately.
3. Run focused playtests and inspect console. Do not claim untested features work.
4. Stop and save local place; verify timestamp/size; update docs/STATE.md.
5. Updating gameplay must never regenerate or reposition scenery.

## Delegation
Use GPT-6 Sol Low for bounded inexpensive subtasks with exclusive files and a precise interface. Main agent owns Studio writes/integration. Wait for messages when no independent work remains.

## Assets
No blanket exclusion of licensed models. Record sources/terms for borrowed assets. Avoid recognizable major-company logos. Noncommercial status is not an automatic exemption from license conditions. Blender integration is optional.
