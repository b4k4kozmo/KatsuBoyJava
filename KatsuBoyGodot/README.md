# Adventure of Katsu Boy 2D — Godot 4 port

This is a GDScript port of the Java (Swing) game in `../KatsuboyV2`, the newer
of the two versions in this repo. It is built for **Godot 4.5.1** and runs with
no add-ons.

## Running it

1. Open Godot 4.5.1 → **Import** → pick `KatsuBoyGodot/project.godot`.
2. Let it import the assets once (a few seconds), then press **F5**.

**If you want to add maps, monsters, items or sounds, read
[AUTHORING.md](AUTHORING.md)** — most of that is done in the editor without
touching code. This file is about how the port works.

Press **F1** in game for the dev panel (cheats, live stats, click-to-teleport).
Run the regression tests with:

```
godot --headless --path . res://tests/SmokeTest.tscn
```

### Controls

| Action | Key |
|---|---|
| Move | `W` `A` `S` `D` or the arrow keys |
| Confirm / Attack / Talk | `Enter` |
| Shoot (shuriken, costs mana) | `Space` |
| Guard / parry | `Ctrl` |
| Run (once you have the Boots) | `Shift` |
| Character screen & inventory | `C` |
| Pause | `P` |
| Options | `Esc` |
| Full map | `M` |
| Mini map on/off | `X` |
| Debug overlay (coords, A\* path, day state) | `T` |

All of those are named actions in **Project Settings → Input Map**, so they can
be rebound (or given gamepad bindings) without touching code.

## How the port is laid out

The structure is deliberately a mirror of the Java source so you can read them
side by side. Java package → Godot folder, one class per file:

| Java | GDScript |
|---|---|
| `src/main/GamePanel.java`, `src/main/Main.java` | `scripts/main/GamePanel.gd` |
| `src/main/*.java` | `scripts/main/*.gd` |
| `src/entity/*.java` | `scripts/entity/*.gd` |
| `src/monster/*.java` | `scripts/monster/*.gd` |
| `src/object/*.java` | `scripts/object/*.gd` |
| `src/tile/*.java` | `scripts/tile/*.gd` |
| `src/tile_interactive/*.java` | `scripts/tile_interactive/*.gd` |
| `src/environment/*.java` | `scripts/environment/*.gd` |
| `src/ai/*.java` | `scripts/ai/*.gd` |
| `src/data/*.java` | `scripts/data/*.gd` |
| `res/*` | `assets/*` |

Two parts are no longer code, because they are things you edit rather than read:

| Java | Here |
|---|---|
| `res/maps/*.txt` + the tile list in `TileManager` | a Godot **TileSet** (`assets/tiles/katsuboy_tileset.tres`) painted onto **TileMapLayer** nodes in `scenes/maps/*.tscn`. Tile collision is the TileSet's `collision` custom data layer. |
| `AssetSetter` / `EventHandler`'s hardcoded placements | **marker nodes** in those same map scenes (`scripts/authoring/*.gd`). `AssetSetter` walks them at startup and builds the same entities it always did. |

`TileManager` still fills in `tile[id].image`, `tile[id].collision` and
`map_tile_num[map][col][row]`, so collision, pathfinding and the mini map read
exactly what they read before — only the source of that data changed.

Method and field names are the same, just in GDScript's `snake_case`
(`worldX` → `world_x`, `checkCollision()` → `check_collision()`), so searching
for a Java name with an underscore in it will find the same code here.

### The pieces that had to change shape

| Java | Here | Why |
|---|---|---|
| `JPanel` + `Graphics2D` | `Node2D` + `_draw()` | The game is still drawn immediate-mode, top to bottom, in one `_draw()`. `GamePanel` carries the pen state (font, colour, stroke, alpha) and exposes `set_color`/`draw_str`/`fill_rect`/`draw_img`/… so the drawing code reads like the original. Everything the Java code called `g2` is the GamePanel node. |
| `Thread` + 60 FPS `while` loop | `_physics_process` (locked to 60 Hz) + `_process` → `queue_redraw()` | Every counter in the game is frame based, so the fixed 60 Hz tick keeps the original timing. |
| `KeyListener` | `_unhandled_input` → `KeyHandler.key_pressed/key_released` | Same two entry points, same per-state switch. OS key repeat is ignored, which stops menu cursors from skipping. |
| `BufferedImage` | `Texture2D` | `Entity.setup()` still pre-scales each sprite once at load, so it is blitted 1:1 afterwards. |
| `java.awt.Rectangle` | `scripts/util/Rect.gd` | Godot's `Rect2i` is a value type; the game relies on rectangles being mutable objects that get aliased and temporarily shifted, so this is a tiny reference-type stand-in with the same `intersects()` rules. |
| `java.awt.Color` | `Color8(r, g, b, a)` | Same 0–255 values. |
| `RadialGradientPaint` | `GradientTexture2D` (radial fill) | Same five colour stops. It is drawn from a square texture centred on the player so the light stays a circle. |
| `javax.sound.sampled.Clip` | `AudioStreamPlayer` | Same 0–5 volume steps and the same dB values. Looping restarts the stream on `finished`. Which file each slot plays is a `SoundBank` resource, and `SE.gd` names the slots so calls read `play_se(SE.COIN)`. |
| `KeyEvent.VK_*` codes in `KeyHandler` | named actions in the Input Map | `KeyHandler` keeps its per-game-state structure but dispatches on `Action.MOVE_UP` instead of `KEY_W`, so bindings are editor data. |
| `ObjectOutputStream` → `save.dat` | `FileAccess.store_var` → `user://save.dat` | GDScript has no object serialisation, so `DataStorage` gained `to_dict()`/`from_dict()`. `config.txt` moved to `user://` too, because `res://` is read-only in an exported game. |
| `ai/Node.java` | `ai/PathNode.gd` | `Node` is Godot's own base class. |
| `object/SuperObject.java` | dropped | Dead code — nothing referenced it. |

## Bugs fixed along the way

These were all in the Java version. Each one is commented at the site in the
GDScript.

**Crashes**

- **Walking off the edge of the world** threw `ArrayIndexOutOfBoundsException`
  from `CollisionChecker.checkTile`. Anything outside the 100×100 world now
  counts as solid, so you bump into the edge instead.
- **Picking up the Carbuncle** crashed: `OBJ_Carbo` was missing from
  `EntityGenerator`, so `canObtainItem` dereferenced a null item. It is
  registered now, and unknown item names fail safely.
- **Map files referencing tile 44–49** (never set up) would have crashed;
  unset tile slots now fall back to grass.
- **A zero-radius light source** collapsed the radial gradient and rendered
  nothing. Treated as "no light" now.

**Graphics / UI**

- The character screen printed **Life as `life/maxMana`** and **Mana as
  `mana/maxLife`** — the denominators were swapped.
- `getXforAlignToRightText` subtracted **half** the text width, so
  "right-aligned" numbers (item counts, shop prices) overhung their boxes.
- The **day/night debug label** ("Day"/"Night") was drawn over the game at all
  times. It is part of the `T` debug overlay now.
- The **full-screen option** claimed it needed a restart; Godot switches
  straight away.

**Behaviour**

- `checkLevelUp` set `defense = getAttack()` on level up.
- `SaveLoad.save` wrote the player's **mana into the life field**, and
  `load` restored **mana from maxMana**.
- Every monster's `checkDrop` had `if (i >= 50 && 1 < 75)` — a typo for
  `i < 75` that made two drop branches fire at once.
- Slimes and Kamijacks set `speed` but never `defaultSpeed`, so the first time
  one was knocked back it recovered to speed 0 and stopped moving for good.
  `MonsterStats` sets both.
- **The Boots did nothing.** The item existed with the description "Gotta go
  fast!", but had no `use()` and was never placed on a map, so the Run key only
  worked at all if you happened to pick the Ninja or Zilla class. Picking them
  up now unlocks running, and a pair sits on the grass near the start.

**Performance** (this is what made the Java build stutter)

- `PathFinder.setNodes` ran the interactive-tile loop **inside** the 100×100
  grid loop, doing 500,000 iterations per search when it needed 50. The tile
  loop is hoisted out, and the solid grid is cached per map instead of being
  rebuilt every search.
- `PathFinder.resetNodes` walked all 10,000 nodes per search; it now resets
  only the nodes the previous search touched, and node costs are worked out
  when a node is opened rather than for all 10,000 up front. Same A\*, same
  paths.
- `TileManager.draw` tested all 10,000 tiles for visibility every frame; the
  on-screen window is computed directly now.
- `Map.createWorldMap` built ten **4800×4800** images (~92 MB each, ~900 MB
  total) for pictures only ever shown at 500×500. They are rendered at 8 px per
  tile instead — identical on screen, a fraction of the memory.
- `EventHandler` allocated an `EventRect` for every tile of every map — 100,000
  objects, of which 8 are used. They are created on demand.
- `UI.option_top` rewrote `config.txt` **every frame** the options screen was
  open. It saves when you leave the screen.

Measured in this container (headless, software rendering): ~7 ms/frame walking
around, unchanged with a pack of monsters chasing, ~20 ms/frame in the
artificial worst case of all 23 monsters pathfinding at once.

## Things to know

- **Save and config files** live in Godot's user folder, not next to the
  project — `%APPDATA%\Godot\app_userdata\Adventure of Katsu Boy 2D\` on
  Windows, `~/.local/share/godot/app_userdata/…` on Linux,
  `~/Library/Application Support/Godot/app_userdata/…` on macOS.
- The number of maps comes from GamePanel's **Map Scenes** list, so Java's
  fixed `maxMap = 10` (seven of which were empty) is now however many maps you
  actually have.
- `assets/maps/*.txt` are the original text maps. Nothing reads them at run time
  any more — they are kept only so `tools/build_maps.gd` can redo the
  conversion. The `tools/` scripts never run in game.
