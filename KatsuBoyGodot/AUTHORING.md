# Working on Katsu Boy

How to add and change things in the game. Most of it is done in the Godot
editor with no code at all — this walks through each kind of change, then lists
honestly what still needs a script.

Written for Godot 4.5.1. Open `KatsuBoyGodot/project.godot` and press **F5**.

---

## 0. The shape of the project

```
main.tscn                     the game. GamePanel + DevTools.
scenes/maps/*.tscn            one scene per map - tiles and everything on them
assets/tiles/                 the atlas image + katsuboy_tileset.tres
assets/data/                  sound_bank.tres, monsters/*.tres
scripts/                      the game code (see README.md for the Java mapping)
scripts/authoring/            the marker nodes you place in map scenes
tests/SmokeTest.tscn          the regression test
tools/                        one-off conversion scripts, not used at run time
```

`GamePanel` is the whole game. Its **Map Scenes** property (Inspector) is the
list of maps, in order — map 0 is the first one. Its **Sound Bank** property is
where audio comes from.

### Dev tools

Press **F1** in game for a panel with live stats and cheats:

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

Untick **Enabled** on the DevTools node (or delete it) to switch all of that off
for a release build. Nothing else depends on it.

---

## 1. Painting a map

1. Open `scenes/maps/WorldMap.tscn`.
2. Select the **Tiles** node.
3. The TileMap panel opens at the bottom. Pick a tile, paint on the canvas.
4. Save (Ctrl+S) and press F5.

That's it — no conversion step. The game reads the painted layer directly.

**Empty cells count as tile 0 (grass).** For a dungeon where the outside should
be solid, paint the whole rectangle rather than leaving holes.

### Which tiles block movement

Collision is a property of the *tile*, not the map, so a tree blocks everywhere.

1. Select **Tiles**, then in the Inspector click the **Tile Set** resource.
2. The TileSet panel opens at the bottom. Go to **Select** mode and click a tile.
3. In the Inspector, under **Custom Data**, tick or untick **collision**.

That flag is what the collision checker *and* the pathfinder read, so monsters
immediately stop trying to walk through anything you mark solid.

### Adding a new tile

Tiles live in one atlas image because that is what the TileSet paints from.

1. Put your 16×16 PNG in `assets/tiles/`.
2. Add its filename to the end of `TILE_NAMES` in `tools/build_tileset.gd`.
   **Never reorder that list** — position in it is the tile's ID, and every map
   already refers to those IDs.
3. Run:
   ```
   godot --headless --path . --script res://tools/build_tileset.gd
   godot --headless --path . --import
   ```
4. Open the TileSet, select the atlas source, and use **Setup → auto-create
   tiles** (or click the new square) so Godot knows the tile exists. Set its
   `collision` custom data.

---

## 2. Placing things on a map

Every map scene has group nodes to drop markers under:

```
WorldMap
├── Tiles                (TileMapLayer - the terrain)
├── Objects              (items, chests, doors)
├── NPCs
├── Monsters
├── InteractiveTiles     (the dry tree you chop)
├── Events               (pits, save points, doorways between maps)
└── PlayerStart          (where a new game begins)
```

To add something:

1. Right-click the group (say **Monsters**) → **Add Child Node** → **Node2D**.
2. In the Inspector, click the **Script** slot → **Quick Load** →
   `scripts/authoring/MonsterMarker.gd`.
3. Pick what it is from the dropdown that appears (Slime / Snome / …).
4. Drag it onto the map. Turn on grid snapping so it lands on a tile —
   **Configure Snap**, step 48 × 48, then toggle **Use Grid Snap**.

The marker draws the real sprite in the editor so you can see what you placed.
It never draws in game; at startup `AssetSetter` reads the markers and builds
the actual entities from them.

Copy-paste (Ctrl+D) is the fast way to place a lot of the same thing.

| Group | Script | Inspector fields |
|---|---|---|
| Objects | `ObjectMarker.gd` | **Item**; plus **Chest Loot** when Item is Chest |
| NPCs | `NpcMarker.gd` | **Npc** |
| Monsters | `MonsterMarker.gd` | **Monster** |
| InteractiveTiles | `InteractiveTileMarker.gd` | **Kind** |
| Events | `EventMarker.gd` | see below |
| (anywhere) | `PlayerStartMarker.gd` | none — just its position |

**Per-map limits.** Each map has a fixed number of slots: 20 objects, 10 NPCs,
30 monsters, 50 interactive tiles. Go over and the extras are ignored with a
warning in the Output panel. To raise a limit, change the matching number in
`GamePanel._ready()` (`_new_entity_array(20)` and friends).

**Monsters respawn** from their markers whenever the map resets — on death, on
restart, and when the player rests at the healing pool. Objects the player
picked up come back on a full restart.

---

## 3. Events: doors, traps, save points

An **EventMarker** fires when the player walks onto its tile.

| Kind | What it does | Fields it uses |
|---|---|---|
| `ChangeMap` | moves the player to another map | Target Map, Target Col, Target Row |
| `Teleport` | moves the player elsewhere on the same map | Target Col, Target Row |
| `DamagePit` | costs 1 life | — |
| `HealingPool` | full heal, respawns monsters, **saves the game** | — |
| `Speak` | starts a conversation | Speak Npc |

**Required Direction** makes the event only fire when the player walks onto it
facing that way — use `up` for a doorway you enter from below, `any` for a trap.

For `Speak`, drag the NpcMarker into the **Speak Npc** field (or click the
field and pick the node).

Markers are checked top to bottom in the scene tree and the first match wins, so
if two overlap, move the one you want to win higher up.

### Linking two maps

A doorway needs a marker on **both** sides, otherwise the player walks through
and is immediately sent back.

- In `WorldMap`, an event at the door tile: `ChangeMap`, target map 1,
  target col/row = where they should arrive in the hut.
- In `MushroomHut`, an event at *that arrival tile*: `ChangeMap`, target map 0,
  target col/row = the tile just outside the door.

That is how the existing hut door works — copy it as a template.

---

## 4. Making a new map or dungeon

1. **Scene → New Scene → 2D Scene**, rename the root (e.g. `CryptLevel1`).
2. Add a child **TileMapLayer** and name it exactly **`Tiles`**.
3. Select it, and in the Inspector drag `assets/tiles/katsuboy_tileset.tres`
   into its **Tile Set** slot.
4. Paint your level.
5. Add empty **Node2D** children named exactly `Objects`, `NPCs`, `Monsters`,
   `InteractiveTiles`, `Events` (only the ones you need).
6. Save it in `scenes/maps/`.
7. Open `main.tscn`, select **GamePanel**, and in **Map Scenes** press the +
   and drop your new scene in. Its index in that list is its map number.
8. Add `ChangeMap` events on both sides to connect it to an existing map.

The names `Tiles`, `Objects`, `NPCs`, `Monsters`, `InteractiveTiles` and
`Events` are how the game finds things — they must match exactly.

Also add the new scene to `tests/SmokeTest.tscn`'s **Map Scenes** so the tests
exercise it.

---

## 5. Balancing monsters

Open `assets/data/monsters/slime.tres` (or snome / kamijack / shadow_katsu).
Everything is in the Inspector: life, attack, defense, exp reward, speed,
knockback, hitbox, and melee reach and timing.

Changes apply to every monster of that type, everywhere, on the next run.

What is *not* in the resource: which sprites it uses and how it behaves (does it
chase? shoot? swing?). Those differ too much between monsters to be data, so
they live in `scripts/monster/MON_*.gd`.

---

## 6. Sound and music

Open `assets/data/sound_bank.tres`. It is a list of audio streams; drag a
different `.wav` into any slot to change that sound everywhere.

`scripts/data/SE.gd` names the slots, so code reads `gp.play_se(SE.COIN)`
rather than `gp.play_se(1)`. To add a new sound: drop the wav in
`assets/sound/`, append it to the bank, and add a constant to `SE.gd`.

Volume steps (0–5) and their decibel values are in `scripts/main/Sound.gd`.

> One effects channel plays at a time, so a new sound cuts off the previous one.
> That is how the Java version behaved. If you want overlapping hits, that means
> a small pool of `AudioStreamPlayer`s in `Sound.gd`.

---

## 7. Dialogue

Dialogue is still in code, in each character's `set_dialogue()`:
`scripts/entity/NPC_OldMan.gd`, `NPC_NanaMan.gd`, `NPC_Merchant.gd`.

```gdscript
dialogues[0][0] = "Hello, Katsu boy!\nAre you ready for your adventure?"
dialogues[0][1] = "There's something useful in the\nforest."
```

The first index is the **conversation set**, the second is the **line**. `\n`
breaks a line in the box; keep lines short enough to fit.

The old man walks through set 0, then set 1, then set 2 on repeat talks. The
merchant's sets are fixed meanings: 0 greeting, 1 goodbye, 2 too expensive,
3 purchase, 4 pockets full, 5 can't sell equipped, 6 night price, 7 day price,
8 refuses a cursed player.

Event dialogue ("Ouch! You fell down") is in `EventHandler.set_dialogue()`.

---

## 8. Player starting stats

`scripts/entity/Player.gd`, `set_default_values()` — level, life, mana, coins,
starting weapon and shield.

The starting *position* is the **PlayerStart** marker, not code.

---

## 9. What still needs code

These are honest limits of the current design. Each is a small, contained edit.

**A new item** — three steps:
1. Copy an existing script in `scripts/object/`, change `OBJ_NAME`, the sprite
   path, and its numbers.
2. Add one line to the matching function in `scripts/main/EntityGenerator.gd`.
3. Add its name to the `@export_enum(...)` list in
   `scripts/authoring/ObjectMarker.gd`, and a preview sprite to `PREVIEWS`.

After that it is placeable from the editor like anything else. *Skipping step 2
is the one mistake that crashes the game* — it is what broke the Carbuncle in
the Java version.

**A new monster** — same shape: a script in `scripts/monster/` (behaviour and
sprites), a `.tres` in `assets/data/monsters/` (numbers), one line in
`EntityGenerator.get_monster()`, one entry in `MonsterMarker.gd`.

**Anything else:** dialogue, UI layout, the day/night cycle, trading rules,
level-up curve, and the entities' own drawing. The entities are plain objects
rather than nodes — they are drawn and sorted by hand in `GamePanel._draw()`,
which is what keeps the code a line-for-line match with the original Java. Making
them nodes would mean rewriting collision, the draw order and the entity arrays.

---

## 10. Before you commit: run the tests

```
godot --headless --path . res://tests/SmokeTest.tscn
```

It plays the game — title screen, pickups, chests, a key on a door, chopping the
tree, a kill, a shuriken, map transitions, trading, save/load, death and restart
— and prints `47 passed, 0 failed`. It exits non-zero on failure, so it works in
CI.

It is fast and it has already caught real breakage. If you add a system, add a
check for it in `tests/SmokeTest.gd`.

**Gotcha when writing tests:** the runner ticks from `_physics_process`, so one
test "frame" is one game update. An axe swing is a 50 frame cycle — give actions
enough frames to finish before asserting.
