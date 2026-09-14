# Adventure of Katsu Boy 2D — Godot 4 port

This is a GDScript port of the Java (Swing) game in `../KatsuboyV2`, the newer
of the two versions in this repo. It is built for **Godot 4.5.1** and runs with
no add-ons.

## Playing it in a browser

There is a built web demo in [`../web/`](../web/). To try it:

```
cd web && python3 -m http.server 8000
```

and open <http://localhost:8000/>. (A `file://` URL will not work — browsers
refuse to fetch the `.wasm` that way.)

To rebuild it: `tools/build_web.sh /path/to/godot`, which needs the Godot 4.5.1
web export templates installed. The `Web demo` GitHub Actions workflow builds
and publishes the same thing to GitHub Pages on every push to this branch, once
Pages is switched to "GitHub Actions" in the repository settings.

The web build is the same code as the desktop build — nothing was changed or
disabled to make it run in a browser. It exports with threads off, so it works
on any plain static host.

## Running it

1. Open Godot 4.5.1 → **Import** → pick `KatsuBoyGodot/project.godot`.
2. Let it import the assets once (a few seconds), then press **F5**.

**If you want to build a dungeon, start with
[DUNGEON_CHEATSHEET.md](DUNGEON_CHEATSHEET.md)** — one page, no code.
[AUTHORING.md](AUTHORING.md) is the long version: every property of every node,
plus items, sounds, the clock and the classes. This file is about how the port
works.

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
| Debug overlay (coords, A\* path) | `T` |

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
| `RadialGradientPaint` | `shaders/darkness.gdshader` | Same five opacity stops, computed per pixel instead of baked into a screen-sized image that had to be rebuilt whenever the light changed. One colour from the palette, varying only in opacity. |
| `javax.sound.sampled.Clip` | `AudioStreamPlayer` | Same 0–5 volume steps and the same dB values. Looping restarts the stream on `finished`. Which file each slot plays is a `SoundBank` resource, and `SE.gd` names the slots so calls read `play_se(SE.COIN)`. |
| `KeyEvent.VK_*` codes in `KeyHandler` | named actions in the Input Map | `KeyHandler` keeps its per-game-state structure but dispatches on `Action.MOVE_UP` instead of `KEY_W`, so bindings are editor data. |
| `ObjectOutputStream` → `save.dat` | `FileAccess.store_var` → `user://save.dat` | GDScript has no object serialisation, so `DataStorage` gained `to_dict()`/`from_dict()`. `config.txt` moved to `user://` too, because `res://` is read-only in an exported game. |
| `ai/Node.java` | `ai/PathNode.gd` | `Node` is Godot's own base class. |
| `object/SuperObject.java` | dropped | Dead code — nothing referenced it. |

## Beyond the port

A few things were added that the Java version did not have. They are all
optional and all documented in [AUTHORING.md](AUTHORING.md):

- **A clock and calendar.** Time advances in five-minute steps, the HUD shows
  the day, the time and whether it is Morning / Afternoon / Evening / Sunrise /
  Sunset / Night, and the day/night lighting is derived from the hour rather
  than from its own frame counter. Java ran two unrelated timers; now the
  shader, the merchant's night prices and the curse all read one clock.
- **Days of the week.** Sunday shuts the shop but heals more, Monday hurts
  more, Friday is a sale, Saturday hits harder, the rest are ordinary. Each day
  is a resource in `assets/data/days/`, all of it multipliers you can tune.
- **Shaders** for the night filter and for hit sparks, both palette-only.
- **The Wunderboat.** A ticketed boat with a weekly timetable that takes you to
  dungeons, a quest log that tracks what you have cleared, bosses that hand over
  the next route, guide NPCs who walk you to the dock, a collector who takes
  your ticket at the quay, and an ending once everything is cleared. A ticket is
  good for one trip; sailing home is free. Destinations are `.tres` files, so
  adding one is authoring rather than coding — see `ROADMAP.md`.
- **Three classes that mean something.** Samurai, Ninja and Zilla differ in
  melee power, swing speed, thrown damage, armour penetration, a night bonus,
  knock-back both ways, defence, walking speed and what each level gives them.
  Each is a resource in `assets/data/classes/`, and the class screen writes its
  own summary from those numbers.
- **An economy.** A new game starts with nothing. Monsters pay by how dangerous
  they are, dry trees pay a little when chopped, coins lie around the map, and
  re-entering a map refills its monsters — so the shop is always reachable
  without coins ever being free. `ROADMAP.md` has the table and the target
  numbers, and the test suite checks that clearing the starting map buys a boat
  ticket but not the whole shop.
- **Dev tools** (F1) and a **regression test suite**.

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
- **The class menu was a lie.** Picking Samurai gave you a second bokken;
  picking Ninja or Zilla gave you the Boots. That was the whole difference. The
  three are now genuinely different characters, and the numbers live in
  `assets/data/classes/`.
- **The axe was unusable.** Its swing took 50 frames — most of a second — so the
  hardest-hitting weapon in the game had the worst damage per second by a wide
  margin. It is 22 now: still the slowest, but worth carrying.
- **Thrown weapons scaled with the wrong stat.** Projectile damage was
  `attack × dexterity`, and dexterity is the *defence* stat, so how hard you
  threw a shuriken depended on how well you took a punch. It scales with
  strength now, and the class decides whether throwing is your trade.
- **Levelling was broken at both ends.** The exp needed for a level tripled each
  time (5, 15, 45, 135, 405…) while a single Kamijack was worth 250 exp, so the
  first kill could carry a new player three levels at once and no later level was
  ever reachable. On top of that, attack was `strength x weapon`, so each level
  was multiplied by the weapon too and everything died in one hit by level 5.
  The curve is a power of the level now (total = 2 x level^2.5) and attack is
  `strength + weapon`. Monster stats were retuned into tiers to match, and the
  test suite asserts the hits-to-kill and touches-to-die bands at the level the
  player meets each monster.
- **Damage floored at zero.** A monster whose defence was higher than your attack
  took nothing at all from you, with nothing on screen to explain it. The floor
  is 1, like the damage the player takes.
- **The Green Potion restored mana** while its own description said it healed
  life. It heals life now — half your maximum, minimum 4.
- **The player was too wide for his own doorways.** His solid box was 32 of a
  tile's 48 pixels, and the NPCs' were up to 42, so two people could not pass in
  a corridor and a doorway was a squeeze even with corner correction. Everyone
  is 24 now.
- **Things were placed on top of each other.** The candle sat under a dry tree
  and could never be picked up. The test suite now refuses any marker that
  shares a tile with something solid, and any two villagers standing on each
  other.
- **One-tile doorways were a coin flip.** Collision stopped an entity dead the
  moment either leading corner touched a wall, and the player's solid box is 32
  of a tile's 48 pixels. Walking into a doorway a few pixels off centre simply
  did not work, with nothing on screen to say why. `CollisionChecker` now does
  corner correction: when only one corner is clipping, and only slightly, it
  slides the entity clear over the next couple of frames.
- **Followers got stuck against anything the path could not see.** The A\* grid
  knew about terrain only, so a route ran straight through whoever was standing
  in the corridor and the walker pushed at them forever. Bodies now count as
  walls for the duration of a search (never the searcher's own tile or the goal
  tile, so a monster can still chase the player), and a step that turns out to
  be blocked picks another way round rather than repeating itself. `search_path`
  also reports when there is no route at all, so an NPC gives up and goes back
  to wandering instead of grinding at a wall.
- **`slowDown` was never counted down.** Two monsters set a temporary speed
  penalty after being hit and nothing ever ticked it, so the first hit slowed
  them for the rest of their lives. It is a real timer now.
- **The Kamijack was unfightable and unavoidable.** It draws at two tiles but
  kept a one-tile hitbox in its top-left corner, so swings that visibly
  connected missed; and with 6 defence against a starting attack of 1, even a
  clean hit did nothing. Meanwhile it moved at speed 12 — faster than the player
  can run — and hit for 20 against a 6-life player. Five of them wander the
  starting map. The hitbox now matches the body, and the numbers in
  `kamijack.tres` were retuned to something a new player can survive.
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

- **Pixel scaling.** The game renders at exactly 960x576 and the window scales
  that by whole numbers only (`stretch/mode = viewport`,
  `scale_mode = integer`). Fractional scaling is what makes pixel art look
  lumpy — some pixels ending up a row wider than their neighbours — so the
  window letterboxes instead. Every sprite is also pre-scaled at a clean 3x,
  and the few places that drew an already-scaled sprite into a smaller box
  (the shop's coin icon, the map markers) now use their own whole-number sizes.
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
