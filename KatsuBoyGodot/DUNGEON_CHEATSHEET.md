# Dungeon building cheat sheet

Everything you need to build a dungeon in Katsu Boy, on one page. **No code.**
If a step here asks you to open a `.gd` file, it is a bug in this document.

Monsters, items and characters are all files now too — the three sections near
the bottom cover them.

Longer versions: `AUTHORING.md` (every property of every node),
`ROADMAP.md` (why the boat and the tickets work the way they do).

---

## The ten-minute dungeon

1. **Scene → New Scene → 2D Scene.** Rename the root to your dungeon.
2. Attach **`scripts/authoring/DungeonMap.gd`** to the root — the script icon
   above the Inspector, then **Load**.
3. Press **Set up this map**.
4. Paint the floor. Press **Paint the border**.
5. Drag markers under the group nodes.
6. Press **Check this map**. Fix what it says. Repeat.
7. Save into `scenes/maps/`, then add it to
   `main.tscn → GamePanel → Map Scenes` **and** `tests/SmokeTest.tscn`.
8. Connect it: an `EventMarker` on both sides, each with the other map's
   `.tscn` in **Target Scene**.

That is a playable map. The rest of this page is the detail.

---

## The four buttons on the root

| Button | Does | When |
|---|---|---|
| **Set up this map** | makes `Tiles` (with the tile set already in it) and the five group nodes | first thing, on a new map. Safe to press again. |
| **Check this map** | lists every problem in the **Output** panel | constantly |
| **Paint the border** | frames the map so the camera never shows the void | after painting, and again if you extend the map |
| **Tidy up the markers** | snaps every marker to the nearest tile | if you forgot grid snap |

The root also carries a **warning triangle** listing the same problems, and so
does each marker that has one. Click the triangle to jump to the offender.

---

## Painting tiles

**Turn on grid snap first:** magnet icon → **Configure Snap → Grid Step
48 × 48** → tick **Use Grid Snap**. Everything in this game is 48 px.

Select the **Tiles** node, then the **TileMap** tab at the bottom.

| Want | Do |
|---|---|
| draw one tile | pick it in the palette, click |
| draw a line | drag |
| fill a region | **Bucket** tool (`B`), click inside |
| fill the *whole map* with wall, then carve | Bucket with **Ctrl** held |
| rectangle | **Rect** tool (`R`) |
| copy a patch | **Select** (`S`), drag, `Ctrl+C`, `Ctrl+V` |
| erase | right-click, or `E` |

**Work outside-in:** bucket-fill the whole area with a solid tile, then carve
rooms and corridors out of it with floor. Carving is faster than walling, and
you never end up with a room that has a hole in its wall you did not notice.

### Which tiles are walls

A tile blocks movement if its **`collision`** custom data is ticked in
`assets/tiles/katsuboy_tileset.tres`. Nothing in the map scene decides this —
it is a property of the tile itself, so a wall is a wall on every map.

To check or change one: open the tile set, select the tile in the atlas, and
look at **Custom Data → collision** in the Inspector.

**Off the edge of the painted area counts as solid.** That is why
**Paint the border** is decoration rather than a wall — the wall is already
there.

### Adding a new tile to the palette

1. Put the 48×48 art into `assets/tiles/`.
2. Open `assets/tiles/katsuboy_tileset.tres`, select the atlas source, and
   either extend the region or add a new source.
3. Tick **collision** on it if it should block.

---

## The five groups, and what goes in each

```
YourDungeon              ← DungeonMap
├── Tiles                the terrain
├── Objects              items, chests, doors, coins
├── NPCs                 people you talk to
├── Monsters             things that hurt you
├── InteractiveTiles     scenery you can destroy
└── Events               pits, pools, doorways, the boat dock
```

To place something: select the group → **Add Child Node** (`Ctrl+A`) → type the
marker's name → pick what it is in the Inspector → drag it onto a tile.

Markers draw their real sprite in the editor and never draw in game.

**Sub-folders are fine.** `Monsters/Upper Floor` and `Objects/Room 3` work and
keep a big map readable. Order in the tree is preserved.

**Per-map limits:** 40 objects, 10 NPCs, 80 monsters, 50 interactive tiles.
Going over is not an error, it is silently ignored — which is why
**Check this map** counts them for you.

---

## Marker quick reference

### `ObjectMarker` → **Objects**

| Field | Notes |
|---|---|
| **Item** | coins, keys, weapons, potions, Boots, `Chest`, `Door`, or **From Stats** |
| **Item Stats** | the item itself, for `From Stats`. Drag one in from `assets/data/items/`. |
| **Chest Loot** | `Chest` only — what is inside. `From Stats` works here too. |
| **Chest Loot Stats** | what is in the chest, for `From Stats` |
| **Coin Value** | `Kami Coin` only — 1 loose change, 5 a purse, 20 a find. Drawn bigger when it is worth more. |

`Chest` and `Door` block the tile they stand on. Everything else is walked over.

### `MonsterMarker` → **Monsters**

| Field | Notes |
|---|---|
| **Monster** | Slime / Snome / Kamijack / Shadow / Boss / **From Stats** |
| **Stats** | a `MonsterStats`. On a named monster it retunes *this one placement*. On **From Stats** it *is* the monster. On a `Boss`, near-required. |
| **Boss Dungeon Id** | `Boss` only — the dungeon it guards. Killing it clears that dungeon. |
| **Reward Ticket** | `Boss` only — the route its death opens |

Monsters respawn from their markers whenever the map resets: on death, on
restart, and when the player rests at a healing pool. Leaving a map and coming
back refills it — that is the money loop, so a dungeon wants enough monsters to
make a sweep worth doing.

### `NpcMarker` → **NPCs**

| Field | Notes |
|---|---|
| **Npc** | OldMan / NanaMan / Merchant / TicketMan / **From Stats** |
| **Profile** | the character itself, for `From Stats`. Drag one in from `assets/data/npcs/`. |
| **Shop Stock** | `Merchant` only — `ItemStats` to put on the shelf. Empty keeps the built-in stock. |
| **Guide Dungeon Id** | `OldMan` only. Makes him a signpost for that dungeon. |
| **Guide Target** | drag the marker he walks to after talking — usually the Boat dock |

### `InteractiveTileMarker` → **InteractiveTiles**

| Field | Notes |
|---|---|
| **Kind** | `DryTree` — chop it with the Kami Axe, it becomes a stump |

Solid until destroyed. Drops a coin 40% of the time. **Do not stack anything on
one** — the thing underneath is unreachable until the tree is felled, and the
player may not have the axe.

### `EventMarker` → **Events**

| Field | Notes |
|---|---|
| **Kind** | see below |
| **Required Direction** | `any`, or the way the player must be walking |
| **Target Scene** | `ChangeMap` — drag the destination `.tscn` in |
| **Target Col / Row** | the tile they arrive on (`Teleport` and `ChangeMap`) |
| **Speak Npc** | `Speak` — drag the `NpcMarker` |
| **Dock Of** | `Boat` — this dungeon's id |

| Kind | Does |
|---|---|
| `ChangeMap` | to another map |
| `Teleport` | elsewhere on this map |
| `DamagePit` | costs 1 life |
| `HealingPool` | full heal, respawns monsters, **saves the game** |
| `Speak` | starts a conversation |
| `Boat` | opens the timetable — Confirm while standing on it |

First matching event in tree order wins. If two overlap, move the one you want
higher up.

### `PlayerStartMarker`

Exactly one in the whole project. Where a new game begins and where the player
respawns after dying.

---

## Making it a boat destination

1. Copy `assets/data/dungeons/mushroom_cave.tres` in
   `assets/data/dungeons/`. Fill in:

   | Field | Notes |
   |---|---|
   | **Id** | lower case, no spaces. **Never rename after a save exists** — saves look dungeons up by id. |
   | **Display Name** | what the boat menu calls it |
   | **Scale** | `MINI` (a handful of rooms) or `MAJOR` (a real dungeon) — a label for the player, nothing mechanical |
   | **Sail Days** | tick the days the boat runs. All seven = no timetable. |
   | **Ticket Id** | usually the same string as Id. Empty = needs no ticket. |
   | **Ticket Price** | what Kami Mart charges. 0 = never sold, so something must drop it. |
   | **Sold From Start** | off for a route the player must be *given* first; the shop stocks it once they have held one |
   | **Unlocked By** | the dungeon whose boss must fall first. Empty = open from the start. |
   | **Hint** | one sentence, in character. Guides read it out. |

   **Leave Map Index, Arrive Col and Arrive Row alone.** They fill themselves
   in.

2. Drag that resource into the map root's **Dungeon Info** slot.
3. Put an `EventMarker` on the pier: Kind `Boat`, **Dock Of** = the dungeon's id.
   *That marker's tile is where the boat puts the player down* — there is no
   arrival tile to type, and moving the dock moves the landing.
4. Put a boss in: `MonsterMarker`, Monster `Boss`, **Boss Dungeon Id** = the
   dungeon's id, **Reward Ticket** = the route its death opens. Without a boss
   the dungeon can never be cleared and the ending never unlocks —
   **Check this map** says so.
5. Add the resource to `main.tscn → GamePanel → Dungeons`, and the same in
   `tests/SmokeTest.tscn`.

The ending needs no updating. It fires when every dungeon in that list is
cleared, so adding one automatically makes the ending harder to reach.

---

## Adding an item, with no code

1. Sprite into `assets/objects/`. One 48×48 PNG.
2. Copy `assets/data/items/example_weapon.tres` or `example_consumable.tres`.
3. Fill it in:

   | Group | What to set |
   |---|---|
   | (top) | **Display Name** (also the save key — never rename one that exists), **Sprite**, **Description**, **Price** |
   | **Kind** | `Sword` / `Axe` / `Shield` / `Light` / `Consumable` / `Pickup` |
   | **Weapon** | **Attack Value**, **Attack Area** (reach in pixels), **Knock Back Power**, **Motion 1 / 2 Duration** (wind-up, then swing — the biggest lever on a weapon) |
   | **Shield** | **Defense Value** |
   | **Light** | **Light Radius** in pixels. The candle is 250. |
   | **Effect** | tick any of *heal life*, *restore mana*, *cure the curse*, *rest until sunrise*, *unlock running*. Then **Heal Amount** (flat) and **Heal Share** (percentage of your maximum, so it stays worth buying at level 15), the same pair for mana, and a **Use Message**. |
   | **Inventory** | **Stackable**, **Use Sound** |

4. Add it to `main.tscn → GamePanel → Items` **and** `tests/SmokeTest.tscn`.
5. `ObjectMarker` → **Item** = `From Stats` → drag the resource into
   **Item Stats**.

> Step 4 matters because a saved bag holds item *names*. Anything in
> `assets/data/items/` is found by name even if you forget, but the list is the
> documented place and the one the tests read.

---

## Adding a character, with no code

1. Sprites into `assets/npc/`. Two frames per direction; Down alone is enough
   to start — the other three fall back to it.
2. Copy `assets/data/npcs/example_villager.tres`.
3. Fill it in:

   | Group | What to set |
   |---|---|
   | (top) | **Display Name** — what the dialogue box calls them |
   | **Looks** | **Frames Down / Up / Left / Right**, **Sprite Scale** |
   | **Body** | **Solid Area** — `(12, 20, 24, 26)` is what the stock NPCs use. **Walk Speed** — 0 stands still, 2 is a slow amble, the player walks at 4. **Restlessness** — frames between turns. |
   | **Talking** | **Conversations** — a list of `NpcDialogue`, one per exchange. **Voice** — a sound bank number. |
   | **Gift** | an `ItemStats` handed over the first time you talk, once per run, plus its **Gift Message** |

4. `NpcMarker` → **Npc** = `From Stats` → drag the resource into **Profile**.

**Conversations move forward.** Talking again goes to the next one and the last
repeats forever. Three conversations is a character who has something new to say
twice and then settles — which is what makes a village feel written rather than
recorded. One conversation is a signpost, which is also fine.

An `NpcDialogue` is a **Label** (a note to yourself, never shown) and **Lines**
in order. Confirm moves to the next. Lines wrap for you; `\n` forces a break.

---

## Adding a monster, with no code

1. Sprites into `assets/monster/`. Two frames per direction; one direction is
   enough to start.
2. Copy `assets/data/monsters/example_custom.tres`.
3. Fill it in:

   | Group | What to set |
   |---|---|
   | **Stats** | Max Life, Attack, Defense, Exp Reward, Speed, Knock Back Power |
   | **Hitbox** | **Solid Area** — smaller than the sprite. The player's is 24×24 inside a 48×48 tile; matching that is a good default. |
   | **Looks** | two PNGs into **Frames Down**; the other three directions fall back to Down if empty. **Sprite Scale** 2 for something two tiles across. |
   | **Behaviour** | `Wander` drifts and hurts on contact · `Chaser` paths to you · `Fighter` chases and swings · `Shooter` chases, swings and throws |
   | **Drops** | weighted rows — see below |
   | **Melee attack** | only for Fighter/Shooter: **Attack Area** is the reach, **Motion 1/2 Duration** the wind-up and the swing |

4. `MonsterMarker` → **Monster** = `From Stats` → drag the resource into
   **Stats**.

### Drop tables

Each row is an **Item** (Coin / Heart / Green Potion / Mana Crystal /
**Nothing**) and a **Weight**. Weights are relative, not percentages: `55/20/25`
and `11/4/5` are the same odds, so you can add a row without redoing the others.
Coin rows also take **Coin Min / Max** and roll inside that range.

`Nothing` is a real row — use it for the share of kills that pay out nothing,
rather than leaving the weights short of 100.

A rough guide, from the monsters already in the game:

| Tier | Coins per kill | Example |
|---|---|---|
| bottom | 1–3, often | Slime |
| middle | 3–10 | Snome |
| top | 25–40 | Shadow |

---

## What "Check this map" catches

Each of these loads fine and then does not work, which is why the check exists.

| Message | What went wrong |
|---|---|
| *No TileMapLayer called 'Tiles'* | press **Set up this map** |
| *Missing the 'X' node* | same |
| *Nothing is painted yet* | you have not started |
| *N markers under X, but only M fit* | over the per-map limit; the rest are ignored at load |
| *A and B are on the same tile and one of them is solid* | a chest on a doorway, a tree on a candle |
| *X is on a solid tile* | something spawned inside a wall — unreachable |
| *Not on the 48 px grid* | turn on grid snap, or press **Tidy up the markers** |
| *N locked door(s) and no Key on this map* | a dead end that looks like content |
| *No Boat marker* | no way off the island |
| *The Boat marker says Dock Of = 'x' but this map is 'y'* | the boat will offer to sail you where you already are |
| *No Boss marker* | this dungeon can never be cleared, so the ending never unlocks |
| *The Boss says it guards 'x' but this map is 'y'* | killing it clears the wrong dungeon |
| *Monster is 'From Stats' but the Stats slot is empty* | an invisible monster with one hit point |
| *No Target Scene, so this door uses map number N* | works until somebody reorders the map list |

---

## Generating a skeleton instead

For a room-and-corridor layout with a dock, a boss, monsters and chests already
placed, add an entry to `tools/build_dungeon_map.gd` and run:

```
godot --headless --path . --script tools/build_dungeon_map.gd
```

It is an ordinary scene afterwards — open it and change whatever you like.
**Re-running overwrites it**, so once you start editing by hand, take the entry
back out of the script.

---

## Before you call it done

```
godot --headless --path . res://tests/SmokeTest.tscn
```

The suite checks every map in the list: every arrival tile is walkable, every
dungeon id is unique, every map points at a real scene, and every marker is on
the grid and not in a wall. It catches the mistakes that are easy to make here.

Then play it. Walk the whole map, take every corridor, and open every chest.
