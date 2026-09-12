# Working on Katsu Boy

Everything you can change without writing code, and exactly where it lives in
the Godot editor. Godot 4.5.1 — open `KatsuBoyGodot/project.godot`, press **F5**
to play.

- [Where things are](#where-things-are)
- [Finding your way around a map scene](#finding-your-way-around-a-map-scene)
- [Where the tile editor is](#where-the-tile-editor-is)
- [Painting maps](#painting-maps)
- [Placing things on a map](#placing-things-on-a-map)
- [Node reference](#node-reference)
- [Building a new map or dungeon](#building-a-new-map-or-dungeon)
- [Settings you can tune](#settings-you-can-tune)
- [Controls and rebinding](#controls-and-rebinding)
- [Dev tools](#dev-tools)
- [What still needs code](#what-still-needs-code)
- [Running the tests](#running-the-tests)

---

## Where things are

| I want to change... | Open |
|---|---|
| the terrain of a map | `scenes/maps/<Map>.tscn` → select **Tiles** |
| what's on a map (items, monsters, NPCs, doors) | `scenes/maps/<Map>.tscn` → the group nodes |
| which tiles block movement | `assets/tiles/katsuboy_tileset.tres` |
| monster stats | `assets/data/monsters/*.tres` |
| the player's starting stats and speeds | `assets/data/player.tres` |
| sounds and music | `assets/data/sound_bank.tres` |
| the list of maps, colours, day/night length | `main.tscn` → select **GamePanel** |
| key bindings | Project Settings → Input Map |
| dialogue | `scripts/entity/NPC_*.gd` (code) |

---

## Finding your way around a map scene

A map is 100 x 100 tiles — 4800 x 4800 pixels — and the editor opens at the
top-left corner, so the thing you want is usually off screen. Three ways to get
to it:

**Frame a node.** Click it in the **Scene** dock and press **F**. The 2D view
jumps to it and zooms in. This is the fastest way to find the merchant, a
doorway, or the player start — click it in the tree, press F, and you're there.

**Get around by hand.** Middle-mouse drag (or space + drag) pans. Scroll wheel
zooms. **Shift+F** toggles freelook-style panning with the arrow keys.

**See the whole map.** Select the **Tiles** node and press **F** to frame the
entire painted area at once, then zoom in where you want to work.

### Playing a single map

Walking from the start to a dungeon every time you want to test it gets old.
Open `main.tscn`, select **GamePanel**, and set **Debug Start Map** to that
map's number — the game boots straight into it, on that map's PlayerStart (or
somewhere sensible if it hasn't got one). Set it back to `-1` when you're done.

In game, **F9** jumps to the next map, which is quicker for a look around.

> Map numbers are positions in GamePanel's **Map Scenes** list: `WorldMap` is 0,
> `MushroomHut` is 1, `TestMap` is 2.

---

## Where the tile editor is

This trips everyone up once.

**The TileMap editor only appears when you select a TileMapLayer node.** And you
have to open the map's own scene to do that — in `main.tscn` the maps are
*instances*, and Godot won't let you edit an instance in place.

1. **FileSystem** dock (bottom left) → `scenes/maps/` → double-click
   **`WorldMap.tscn`**.
2. In the **Scene** dock (top left), click the **`Tiles`** node.
3. A **TileMap** panel appears along the bottom of the window, with the tile
   palette in it. If you don't see it, drag the bottom panel upwards — it can
   be collapsed to nothing.
4. Pick a tile from the palette and paint on the canvas. **Ctrl+S** to save.

To edit the TileSet itself (which tiles block movement, adding tiles), click
the **Tile Set** property in the Inspector while `Tiles` is selected — the
bottom panel switches to a **TileSet** tab.

---

## Painting maps

With `Tiles` selected, the bottom panel gives you the usual tools: pencil,
line, rectangle, bucket fill, and an eraser (hold right mouse button). Rectangle
select and copy/paste work for moving chunks of a map around.

The maps are 100×100 tiles. The player sees about 20×12 at a time.

> **Paint every cell.** An unpainted cell counts as tile 0 (grass) and is
> walkable. For a dungeon, fill the whole rectangle with wall first, then carve
> the rooms out of it.

### Which tiles block movement

Collision belongs to the *tile*, not the map, so a tree blocks everywhere at
once.

1. Select **Tiles** → in the Inspector click the **Tile Set** resource.
2. Bottom panel → **TileSet** tab → **Select** mode → click a tile.
3. In the Inspector, **Custom Data → collision**, tick or untick.

That one flag is read by both the collision checker and the pathfinder, so
monsters immediately stop trying to walk through anything you mark solid.

### Adding a new tile

All tiles live in one atlas image, because that's what the TileSet paints from.

1. Put your 16×16 PNG in `assets/tiles/`.
2. Add its filename to the **end** of `TILE_NAMES` in `tools/build_tileset.gd`.
   **Never reorder that list** — a tile's position in it is its ID, and every
   map already refers to those IDs.
3. Run, from the project folder:
   ```
   godot --headless --path . --script res://tools/build_tileset.gd
   godot --headless --path . --import
   ```
4. Open the TileSet, select the atlas source, and click the new square (or use
   **Setup → auto-create tiles**) so Godot knows it exists. Set its `collision`.

---

## Placing things on a map

Each map scene has group nodes to put markers under:

```
WorldMap
├── Tiles                (TileMapLayer — the terrain)
├── Objects              items, chests, doors
├── NPCs
├── Monsters
├── InteractiveTiles     the dry tree you chop
├── Events               pits, save points, doorways between maps
└── PlayerStart          where a new game begins
```

**The markers are real node types.** You don't attach scripts by hand:

1. Select the group (say **Monsters**).
2. **Add Child Node** (the **+** button, or **Ctrl+A**).
3. Type the node's name in the search box — `MonsterMarker`, `ObjectMarker`,
   `NpcMarker`, `InteractiveTileMarker`, `EventMarker`, `PlayerStartMarker`.
   They have their own icons in the list.
4. Pick what it is from the dropdown in the Inspector.
5. Drag it onto a tile.

**Turn on grid snapping** so things land on tiles: the magnet icon in the
toolbar, then **Configure Snap → Grid Step 48 × 48**, and enable **Use Grid
Snap**. (A marker that's slightly off-grid still snaps to the nearest tile at
run time, so this is for your eyes, not correctness.)

Each marker draws its real sprite in the editor, so you can see what you placed.
Markers never draw in game — at startup `AssetSetter` reads them and builds the
actual entities.

> **Watch out for markers on the same tile.** A Slime spawns on tile 8,46 in
> `WorldMap` — the same tile as the doorway to the hut — so it can physically
> stand in the door and block it. That came straight from the Java version.
> Now that both are nodes you can just drag one of them off the other.

**Per-map limits:** 20 objects, 10 NPCs, 30 monsters, 50 interactive tiles.
Going over is ignored with a warning in the **Output** panel. To raise one,
change the matching number in `GamePanel._ready()` (`_new_entity_array(20)`).

**Monsters respawn** from their markers whenever the map resets — on death, on
restart, and when the player rests at a healing pool. Objects the player picked
up come back on a full restart.

---

## Node reference

### `MonsterMarker`
Under **Monsters**. Spawns one monster.

| Property | What it does |
|---|---|
| **Monster** | Slime / Snome / Kamijack / Shadow |

Its numbers come from `assets/data/monsters/<name>.tres`.

### `NpcMarker`
Under **NPCs**. Spawns a character you can talk to.

| Property | What it does |
|---|---|
| **Npc** | OldMan / NanaMan / Merchant |

The Merchant opens the shop. Dialogue is in that NPC's script.

### `ObjectMarker`
Under **Objects**. An item, chest or door.

| Property | What it does |
|---|---|
| **Item** | which item — coins, keys, weapons, Boots, Chest, Door… |
| **Chest Loot** | only used when Item is `Chest`: what's inside |

Pickup-only items (coins, hearts, mana, Boots) are used the moment you walk over
them. Weapons, shields, keys and potions go into the inventory. `Door` and
`Chest` are obstacles you interact with using the Confirm key.

### `InteractiveTileMarker`
Under **InteractiveTiles**. Scenery you can destroy.

| Property | What it does |
|---|---|
| **Kind** | DryTree — chop it with the Kami Axe, it becomes a stump |

The pathfinder treats these as solid until they're destroyed.

### `EventMarker`
Under **Events**. Fires when the player steps on its tile.

| Property | What it does |
|---|---|
| **Kind** | see the table below |
| **Required Direction** | `any`, or the way the player must be walking for it to fire |
| **Target Map** | `ChangeMap` only — index into GamePanel's Map Scenes |
| **Target Col / Row** | the tile the player arrives on (`Teleport` and `ChangeMap`) |
| **Speak Npc** | `Speak` only — drag the NpcMarker to talk to |

| Kind | Does |
|---|---|
| `ChangeMap` | moves the player to another map |
| `Teleport` | moves the player elsewhere on the same map |
| `DamagePit` | costs 1 life |
| `HealingPool` | full heal, respawns monsters, **saves the game** |
| `Speak` | starts a conversation |

Markers are checked top to bottom in the scene tree and the **first match
wins**, so if two overlap, move the one you want higher up.

**Linking two maps** needs a marker on *both* sides, or the player walks through
and is immediately sent back:

- In `WorldMap`, at the door tile: `ChangeMap`, Target Map `1`, Target Col/Row =
  where they arrive inside.
- In `MushroomHut`, at *that arrival tile*: `ChangeMap`, Target Map `0`, Target
  Col/Row = the tile just outside the door.

The existing hut door is set up exactly like this — copy it as a template.

### `PlayerStartMarker`
Anywhere in any map scene. Where a new game begins and where the player
respawns. Put exactly one in the whole project. No properties — just its
position. Without one, the game falls back to tile 94,94 on map 0.

---

## Building a new map or dungeon

1. **Scene → New Scene → 2D Scene**. Rename the root, e.g. `CryptLevel1`.
2. **Add Child Node → TileMapLayer**. Name it exactly **`Tiles`**.
3. Select it. In the Inspector, drag `assets/tiles/katsuboy_tileset.tres` into
   the **Tile Set** slot.
4. Paint the level (bucket-fill wall first, then carve).
5. Add empty **Node2D** children named exactly `Objects`, `NPCs`, `Monsters`,
   `InteractiveTiles`, `Events` — only the ones you need.
6. Save into `scenes/maps/`.
7. Open `main.tscn`, select **GamePanel**, find **Map Scenes** in the Inspector,
   press **+**, and drop your scene in. **Its position in that list is its map
   number** — that's what an EventMarker's Target Map refers to.
8. Add `ChangeMap` events on both sides to connect it to an existing map.

> The names `Tiles`, `Objects`, `NPCs`, `Monsters`, `InteractiveTiles` and
> `Events` are how the game finds things. They must match exactly.

Also add the new scene to **`tests/SmokeTest.tscn`**'s Map Scenes, so the tests
cover it.

---

## Settings you can tune

### `main.tscn` → GamePanel (Inspector)

| Group | Property | What it does |
|---|---|---|
| | **Map Scenes** | the maps, in order. Index = map number |
| | **Sound Bank** | which audio set to use |
| | **Debug Start Map** | boot straight into this map. -1 = off |
| Time of day | **Frames Per Time Step** | game frames between clock ticks. 60 = one tick a second |
| Time of day | **Minutes Per Time Step** | in-game minutes each tick adds |
| Time of day | **Start Day / Hour / Minute** | when a new game begins. Day 0 = Sunday |
| Time of day | **Day Rollover Hour** | when the calendar flips over. 0 = midnight |
| Time of day | **Show Clock** | the clock window on the HUD |
| Day / night | **Sunrise Start / End Hour** | dark before, light after |
| Day / night | **Sunset Start / End Hour** | light before, dark after |
| Day / night | **Midday Hour** | when "Morning" becomes "Afternoon" |
| Day / night | **Evening Hour** | when "Afternoon" becomes "Evening" |
| Day / night | **Night Darkness** | 0 = no night, 255 = pitch black |
| Palette | **Color Green / Black / Pink / White** | the four colours the whole UI is drawn from |

### The clock

Time moves in steps, Harvest Moon style: every second of real time the clock
jumps forward five in-game minutes, so a full 24 hours takes about five real
minutes. The HUD shows the day, the time, and which part of the day it is.

At the defaults:

| Hours | Shows as | Light |
|---|---|---|
| 5:00 – 6:00 | Sunrise | fading up |
| 6:00 – 12:00 | Morning | full daylight |
| 12:00 – 17:00 | Afternoon | full daylight |
| 17:00 – 20:00 | Evening | full daylight |
| 20:00 – 21:00 | Sunset | fading down |
| 21:00 – 5:00 | Night | full dark |

**The clock is the single source of truth.** The darkness shader, the merchant's
night prices, the night curse and the HUD all read the same hour, so moving
`Sunset Start Hour` moves all of them together. There is no separate lighting
timer any more.

Sleeping in a tent wakes you at **Sunrise End Hour** on the next day.

In game, **F3** pushes the clock forward three hours, which is the quickest way
to see a night behaviour.

### `assets/data/player.tres`

Starting level, life, mana, ammo, strength, dexterity, coins and exp curve;
starting weapon, shield and projectile; and movement:

| Property | What it does |
|---|---|
| **Walk Speed** | pixels per frame normally |
| **Boots Walk Speed** | pixels per frame once you have the Boots |
| **Run Speed** | while holding the Run key |
| **Requires Boots To Run** | off = the player can sprint from the start |

> Running used to be unreachable: the Boots item existed but did nothing, so the
> Run key only worked if you picked the Ninja or Zilla class. Picking up the
> Boots now unlocks it, and there's a pair on the grass near the start. Untick
> **Requires Boots To Run** if you'd rather sprint from the beginning.

### `assets/data/monsters/*.tres`

Life, attack, defense, exp reward, speed, knockback, hitbox, and melee reach
and timing. Applies to every monster of that type everywhere.

Not in here: which sprites it uses and how it behaves (chase? shoot? swing?).
Those are too different between monsters to be data — they live in
`scripts/monster/MON_*.gd`.

### `assets/data/sound_bank.tres`

A list of audio streams. Drag a different `.wav` into a slot to change that
sound everywhere. `scripts/data/SE.gd` names the slots.

> One effects channel plays at a time, so a new sound cuts off the previous one —
> that's how the Java version behaved. Overlapping hits would mean a small pool
> of `AudioStreamPlayer`s in `scripts/main/Sound.gd`.

---

## Controls and rebinding

Keys live in **Project Settings → Input Map**. Nothing in the game refers to a
key code, so you can rebind there, add a second key, or add a gamepad button,
and the in-game Controls screen updates to match.

| Action | Default |
|---|---|
| `move_up` / `down` / `left` / `right` | W A S D, and the arrow keys |
| `confirm` | Enter |
| `shoot` | Space |
| `guard` | Ctrl |
| `run` | Shift |
| `pause` | P |
| `character_screen` | C |
| `options` | Esc |
| `world_map` | M |
| `mini_map` | X |
| `debug_overlay` | T |

To add an action the game reacts to, add it in Project Settings, then add a
constant to `scripts/data/Action.gd` (including in `ALL`) and handle it in
`scripts/main/KeyHandler.gd`.

---

## Dev tools

Press **F1** in game. The DevTools node lives in `main.tscn`; untick **Enabled**
in the Inspector (or delete the node) for a release build — nothing depends on
it.

| Key | Does |
|---|---|
| F1 | show/hide the panel |
| F2 | god mode |
| F3 | cycle day / dusk / night / dawn |
| F4 | give one of every item |
| F6 | full heal |
| F7 | kill every monster on this map |
| F8 | respawn monsters |
| F9 | jump to the next map |
| F10 | +1000 coins, +500 exp |
| left click | teleport to that tile |

The dev keys are raw key codes on purpose, so they can't clash with anything a
player rebinds.

---

## How the screen is put together

`main.tscn` draws in layers, each a real node, ordered by **z_index**:

| Node | z | Draws |
|---|---|---|
| `World` | -1 | the TileMapLayer terrain, scrolled to follow the player |
| `GamePanel` | 0 | interactive tiles and entities, depth-sorted |
| `LightingOverlay` | 5 | day/night darkness (shader) |
| `EffectsLayer` | 6 | hit sparks (shader) |
| `HudLayer` | 10 | mini map, HUD, menus, debug text |

That's why night darkens the world but not your health bar. All of them extend
`Graphics2D`, which carries the Java-style pen state (`set_color`, `draw_str`,
`fill_rect`, `draw_img`), so any of them can be passed as the `g2` argument.

### Shaders

Both live in `shaders/` and only ever use colours from the palette.

**`darkness.gdshader`** on `LightingOverlay` — the night filter and the circle
of light around the player. Select the node, expand **Material → Shader
Parameters**:

| Parameter | What it does |
|---|---|
| **Darkness** | how black full night gets |
| **Bands** | 0 = smooth falloff. Higher posterises the light into that many steps, for a chunkier look |
| **Dark Color** | the colour night is painted in — fed from the palette at run time |

Light position, radius and the day/night fade are driven by the game each frame,
so changing them in the Inspector won't stick.

**`impact.gdshader`** on `EffectsLayer` — the expanding ring when a hit lands.
One material draws every spark, so each one's colour and age ride in on the
draw call's modulate.

| Where | What |
|---|---|
| `EffectsLayer` → **Enabled** | turn sparks off without deleting the node |
| `EffectsLayer` → **Impact Life** | how long a spark lasts, in frames |
| `EffectsLayer` → **Impact Size** | how big it is, in pixels |
| Material → **Cells** | how coarsely the ring is pixelated |
| Material → **Thickness** | how thick the ring starts out |

Sparks fire from `Player.damage_monster`, `Player.damage_interactive_tile` and
`Entity.damage_player`. To add one somewhere else:

```gdscript
gp.effects.add_impact_on(some_entity, gp.ui.kamiwhite)
```

Deleting the `EffectsLayer` node is safe — every call site checks for it.

---

## What still needs code

Honest limits of the current design. Each is small and contained.

**A new item** — three steps:
1. Copy a script in `scripts/object/`; change `OBJ_NAME`, the sprite path and
   the numbers.
2. Add one line to `scripts/main/EntityGenerator.gd`.
3. Add the name to the `@export_enum(...)` list in
   `scripts/authoring/ObjectMarker.gd`, and a preview sprite to `PREVIEWS`.

Then it's placeable from the editor like anything else. **Skipping step 2 is the
one mistake that crashes the game** — it's what broke the Carbuncle in the Java
version.

**A new monster** — same shape: a script in `scripts/monster/` (behaviour and
sprites), a `.tres` in `assets/data/monsters/` (numbers), one line in
`EntityGenerator.get_monster()`, one entry in `MonsterMarker.gd`.

**Dialogue** — in each character's `set_dialogue()`:

```gdscript
dialogues[0][0] = "Hello, Katsu boy!\nAre you ready for your adventure?"
dialogues[0][1] = "There's something useful in the\nforest."
```

First index is the conversation set, second is the line, `\n` breaks a line. The
old man cycles sets 0 → 1 → 2 on repeat talks. The merchant's sets have fixed
meanings: 0 greeting, 1 goodbye, 2 too expensive, 3 purchase, 4 pockets full,
5 can't sell equipped, 6 night price, 7 day price, 8 refuses a cursed player.
Event dialogue is in `EventHandler.set_dialogue()`.

**Also code:** UI layout, trading rules, the level-up curve, and the entities'
own drawing. Entities are plain objects rather than nodes — they're drawn and
depth-sorted by hand in `GamePanel._draw()`, which is what keeps this code a
line-for-line match with the original Java. Making them nodes would mean
rewriting collision, draw order and the entity arrays.

---

## Running the tests

```
godot --headless --path . res://tests/SmokeTest.tscn
```

It plays the game — title screen, pickups, chests, a key on a door, chopping the
tree, a kill, a shuriken, map transitions via event markers, trading, save/load,
death and restart, the Boots and running, and the world edges — and prints
`53 passed, 0 failed`. It exits non-zero on failure, so it works in CI.

It's fast and it has already caught real breakage. If you add a system, add a
check to `tests/SmokeTest.gd`.

> **Writing tests:** the runner ticks from `_physics_process`, so one test
> "frame" is one game update. An axe swing is a 50-frame cycle — give actions
> enough frames to finish before you assert.
