# Turning Katsu Boy into a full game

`AUTHORING.md` covers *how* to change things. This is about *what to build and
in what order*, based on what the game actually contains today.

---

## What is already here

| | |
|---|---|
| Monsters | 4 — Slime, Snome, KamiJack, Shadow Katsu |
| NPCs | 3 — Merchant, NanaMan, Old Man |
| Items / objects | ~15 — bokken, axe, shield, puffa, potion, key, boots, candle, chest, coin, heart, mana crystal, shuriken… |
| Maps | 3 — WorldMap, MushroomHut, TestMap |
| Classes | 3 — Samurai, Ninja, Zilla |
| Systems | levels and exp, inventory, shop, projectiles, guard/parry, A* monster chase, save/load, day–night clock, day-of-week effects |

That is a lot of working machinery. The gap is not systems — it is that nothing
asks the player to use them.

## The honest diagnosis

The loop right now is:

> walk → fight something → gain exp and coins → buy a better weapon → walk

That is a treadmill with no destination. Three specific things are missing.

**1. There is no goal.** `UI.gd` declares `game_finished` and nothing ever sets
it. There is no boss, no ending, no quest, nothing to complete. A player has no
answer to "what am I supposed to be doing?", and no moment where the game says
they won.

**2. There is no escalation.** All three maps are open from the start and
monsters do not get meaningfully harder in a structured way. Levelling makes
numbers bigger but unlocks nothing, so power has nowhere to go.

**3. The best idea in the game is unused.** The day-of-week system — Monday
hurts more, Friday is a sale, Saturday you hit harder, Sunday the shop shuts but
food heals more — is the most distinctive thing here and *no content exploits
it*. Nothing ever makes the player think "I should wait until Saturday for
this." That is a free hook already built and paid for.

## The smallest thing that is a complete game

Do not plan a sprawling RPG. Aim for a **two to three hour game with an
ending**, which is a real, finishable, shippable thing:

```
Kami Mart (hub, shop, save)
      |
      +-- Dungeon 1  ->  boss  ->  KEY ITEM 1
      +-- Dungeon 2  ->  boss  ->  KEY ITEM 2
      +-- Dungeon 3  ->  boss  ->  KEY ITEM 3
                                      |
                            3 keys open the Shrine
                                      |
                               final boss -> ending
```

Three dungeons, three bosses, three key items, a locked final area, an ending.
Everything in that diagram is already supported by the framework except the
quest tracking and the ending itself.

Lean the week into it, because you already have it:

- One dungeon's boss is only beatable in practice **on Saturday** (damage
  bonus) — or brutal on Monday. The player learns to plan.
- An NPC only appears **on Sunday**.
- A shopkeeper stocks the item you need for dungeon 3 **only on Friday**.

That turns the calendar from decoration into the game's identity, and it costs
almost nothing to build: the `DayEffect` resources and `GameClock.today()`
already exist.

---

## Build order

Ordered so the game is *playable and complete* as early as possible, then gets
bigger. Do not do these out of order — 1 and 2 are what make it a game at all.

### 1. An ending  (half a day)

The single highest-value change. Even with one boss, an ending turns a demo
into a game.

### 2. An objective tracker  (one day)

The player must always be able to answer "what now?". A line on the pause
screen — "Find the Mushroom Key" — is enough. This is the one piece that needs
new code rather than data; see the recipe below.

### 3. One dungeon and one boss  (two to three days)

Prove the whole shape end to end with one of everything before building three.
When dungeon 1 → boss → key → locked door → ending works, the rest is content.

### 4. Dungeons 2 and 3, with their bosses and keys  (a week)

Now it is pure authoring: paint maps, place markers, write `.tres` files. No new
code.

### 5. Day-gated content  (two days)

The bits above that make the week matter.

### 6. Variety pass  (ongoing)

More monsters (cheap — one `.tres` each), more items, NPC dialogue that reacts
to your progress and the day.

---

## Recipes

Each of these uses the framework already in place. `AUTHORING.md` has the
detail on markers, the tile editor and the resource files.

### Add a monster

Cheapest content in the game — mostly a data file.

1. Drop the sprites in `assets/monster/`.
2. Copy `assets/data/monsters/slime.tres` to `yourmonster.tres` and open it in
   the Inspector. Set life, speed, attack, defence, exp reward, the sprites and
   the drop.
3. Copy `scripts/monster/MON_Slime.gd` to `MON_YourMonster.gd`. Point it at the
   new `.tres`. If it behaves like a slime, you are done; override a method
   only if it needs new behaviour.
4. In a map scene, add a `MonsterMarker`, set its `monster` to your script, and
   drag it where you want it.

No other file changes. That is the whole job.

### Add a boss

A boss is a monster with more health, a bigger sprite and a pattern.

1. Steps 1–3 above, with much higher life and attack.
2. Give it phases by overriding `update()` in its script: watch its own
   `life` against `max_life` and switch behaviour at thresholds — chase below
   half, fire projectiles above it. `Projectile.gd` and `MON_Snome.gd` already
   show how to shoot.
3. Place it with a `MonsterMarker` in its dungeon.
4. On death, drop the key item: set the marker's drop, or override the death
   path to spawn the object.

### Add a dungeon map

1. `Scene → New Scene → Node2D`, name it after the dungeon, save into
   `scenes/maps/`.
2. Add a `TileMapLayer` child **named exactly `Tiles`** and set its TileSet to
   `assets/tiles/katsuboy_tileset.tres`. The name matters: `TileManager`
   looks it up by name.
3. Paint with the TileMap editor. Tick `collision` in the TileSet on anything
   solid — see `AUTHORING.md → Which tiles block movement`.
4. Add a `PlayerStartMarker` where the player arrives.
5. Place monsters, objects and NPCs with their markers.
6. Open `main.tscn`, select `GamePanel`, and add the scene to `map_scenes`.
   Its index in that array is its map number.
7. Link it up: put an `EventMarker` on the entrance tile of the map it leads
   from, set it to change map, and give it the new index.
8. Re-run `tools/build_map_borders.gd` so the new map gets its terrain border
   and the camera never shows void past the edge.

### Add an item

1. Sprite into `assets/objects/`.
2. Copy the closest `scripts/object/OBJ_*.gd`. Weapons and shields set attack
   or defence values; consumables override `use()`.
3. Place it with an `ObjectMarker`, or have a monster drop it.

### Add a key item and a locked door

1. Make the key as an item, above. Give it a name you can test against.
2. The door already exists: `OBJ_Door.gd` plus `InteractiveTileMarker`.
3. For the final door, check for all three keys rather than one. That check
   lives in the door's interaction code.

### Add the objective tracker  (needs code)

The only piece with no framework yet. Keep it small:

1. Add a `quest` section to `DataStorage.gd` — a single `quest_stage: int` is
   enough for a linear game — and save/load it in `SaveLoad.gd` alongside
   `level` and `coin`.
2. Add a `GamePanel.quest_stage` and a small lookup of stage number to
   description: `0 → "Find the Mushroom Key"`, `1 → "…"`.
3. Draw the current description on the pause screen in `UI.gd`, next to the
   existing stats.
4. Advance it where the milestones happen — in the boss's death path, or in the
   `EventHandler` event that gives you the key: `gp.quest_stage = 1`.

Resist building a general quest system with objectives and sub-objectives. A
single integer and a lookup table will carry a game this size, and you can
always grow it later.

### Add the ending  (needs a little code)

1. `GamePanel` already has `GAME_OVER_STATE` (6). Add an `ENDING_STATE`
   alongside it.
2. On the final boss's death, set `gp.game_state = gp.ENDING_STATE` and
   `gp.ui.game_finished = true` — the flag already exists and is waiting.
3. In `UI.gd`, draw an ending screen when that state is active, the same way
   the game-over screen is drawn.
4. Report the run to the web high-score board there too:
   `WebScore.post_progress(level, coin)` — see `scripts/web/WebScore.gd`.

### Add day-gated content

`GameClock.today()` gives the current day. To gate anything:

1. In an NPC's or event's update, check the day and behave differently — do not
   spawn, change dialogue, stock a different item.
2. For difficulty rather than presence, use the existing `DayEffect` resources
   in `assets/data/days/` instead of writing new checks; they already scale
   damage, healing and prices.

---

## Things to resist

- **A bigger world instead of a finished one.** Three good dungeons and an
  ending beats a huge empty map. The 100×100 world is already far larger than
  the content that fills it.
- **A general quest system.** See above.
- **More classes.** Three is plenty until the three that exist play
  differently, which is content, not code.
- **More systems.** There are already more mechanics here than content that
  uses them. Crafting, weather, fishing — all of it can wait until the game has
  an ending.

## Where the desktop and web builds differ

They do not, other than two deliberate things:

- The web export uses `gl_compatibility`, because browsers cannot run
  Forward+. Set per-platform in `project.godot`, so desktop is unaffected.
- Dev cheats (`scripts/dev/DevTools.gd`) are editor-only: `_ready()` switches
  the node off unless `OS.has_feature("editor")`. They work when you run from
  the editor and are inert in every export, so the web build cannot be used to
  cheat onto the high-score board.

One project, one set of scripts, three export presets — Web, Linux, Windows and
macOS in `export_presets.cfg`.
