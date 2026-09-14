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
| Maps | 5 — WorldMap, MushroomHut, TestMap, MushroomCave, ShadowDeep |
| Classes | 3 — Samurai, Ninja, Zilla |
| Systems | levels and exp, inventory, shop, projectiles, guard/parry, A* monster chase, save/load, day–night clock, day-of-week effects, **the boat: tickets, a timetable, dungeons, bosses, a quest log and an ending** |

That is a lot of working machinery. The gap is not systems — it is that nothing
asks the player to use them.

## The honest diagnosis

The loop right now is:

> walk → fight something → gain exp and coins → buy a better weapon → walk

That is a treadmill with no destination. Three specific things are missing.

**1. There is no goal.** ~~`UI.gd` declares `game_finished` and nothing ever
sets it.~~ **Built** — see *The boat, the tickets and the quest log* below. The
spine now exists: clear every dungeon, sail home, see an ending. What is still
missing is *content inside* that spine — the two generated dungeons are room
layouts with a boss in the far room, not designed places.

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

### 1. An ending  ✅ done

Sail home with every dungeon cleared and the game ends on a results screen and
reports the run to the web board.

### 2. An objective tracker  ✅ done

`QuestLog` works the answer out from what you have actually done, and the pause
screen prints it. There is no stage counter to keep in step.

### 3. One dungeon and one boss  ✅ done, as a skeleton

Mushroom Cave → boss → the Shadow Deep's ticket → the Shadow Deep → boss →
sail home → ending runs end to end today, and the test suite drives exactly
that path. Both dungeon maps are **generated placeholders**: real rooms, real
walls, real monsters, no design. Replacing them is the next real work.

### 4. Design the dungeons  (a week)

Now it is authoring: open `MushroomCave.tscn`, repaint it into somewhere worth
visiting, give the boss a script of its own, hide something behind a locked
door. No new code. Then the same again for the Shadow Deep, bigger.

### 5. Day-gated content  (two days)

The bits above that make the week matter.

### 6. Variety pass  (ongoing)

More monsters (cheap — one `.tres` each), more items, NPC dialogue that reacts
to your progress and the day.

---

## The boat, the tickets and the quest log

This is the spine of the game and it is all in place. Nothing below needs new
code to grow — adding a destination is a `.tres` file and a map.

```
   DungeonInfo (.tres)          one per destination: map, timetable,
        |                       ticket, price, hint, what unlocks it
        v
   BoatService  -------------> "which routes can you take today, and
        ^   ^                   why not the others"
        |   |
   QuestLog   GameClock         tickets held + dungeons cleared;  the day
        ^
        |
   MON_Boss.check_drop()        clears the dungeon, hands over the next ticket
```

**The pieces**

| File | Job |
|---|---|
| `scripts/data/DungeonInfo.gd` | One destination, as editable data. |
| `assets/data/dungeons/*.tres` | The destinations themselves. Drop them into GamePanel's **Dungeons** list. |
| `scripts/data/QuestLog.gd` | Boarding passes, routes you have ever held a ticket for, dungeons cleared, current objective. Saved with the rest of the game. |
| `scripts/environment/BoatService.gd` | Pure logic: given dungeons + quest log + day, what sails. No nodes, which is why the tests can check the whole timetable without running the game. |
| `scripts/monster/MON_Boss.gd` | A monster that, on death, marks its dungeon cleared and grants the ticket for the next route. |
| `scripts/object/OBJ_BoatTicket.gd` | A ticket as an inventory item — paper, not permission. One script covers every route; `configure()` points it at a `DungeonInfo`. |
| `scripts/entity/NPC_TicketMan.gd` | The collector at the dock. Takes a paper ticket off you and stamps one boarding pass. The only way a ticket becomes passage. |
| `scripts/entity/NPC_Merchant.gd` | Stocks tickets straight from the dungeon files: `sold_from_start` routes always, anything else once you have held its ticket once. |
| `scripts/entity/NPC_OldMan.gd` | With a `guide_dungeon_id` he becomes a signpost: tells you where to go, sets the objective, then walks to the dock so you can follow him. |
| `UI.draw_boat_screen()` | The timetable. Shows every route you could *ever* take with the reason each one is unavailable, so the schedule teaches itself. |
| `UI.draw_pause_screen()` | Prints the objective and the tally. |

**Tickets, passes, and the collector**

A ticket is a thing you carry; a **pass** is permission to board. They are
deliberately separate:

```
Kami Mart / a boss   ->   ticket in your bag   ->   collector at the dock
                                                          |
                                                    one boarding pass
                                                          |
                                                 the boat spends it, once
```

Selecting a ticket in the inventory does nothing but tell you where to take it,
so a route can never be unlocked from inside a dungeon. `NPC_TicketMan` takes
the paper and calls `QuestLog.grant_ticket()`; `EventHandler.sail_to()` calls
`spend_pass()` and refuses if there is nothing to spend. Coming home to the
port, and the victory route, carry no ticket id and are always free.

Handing a ticket over also marks its route **known**, which is what puts it on
Kami Mart's shelf permanently — so the route a boss opened up can be bought
again later, at whatever `ticket_price` says.

**How a route opens up**

There are three gates, and they do different jobs:

- **`unlocked_by`** is the spine. The Shadow Deep does not appear at all until
  the Mushroom Cave is cleared. Use this for story order.
- **`ticket_id` / `ticket_price` / `sold_from_start`** is the door. Tick
  `sold_from_start` for a route Kami Mart sells from the beginning; leave it off
  for one the player must be given first, and it appears on the shelf once they
  have held its ticket once. `ticket_price` of `0` means never for sale.

And one on top of both: **`sail_days`**, the timetable, which turns the
day-of-week system from decoration into planning. The Shadow Deep sails only on
Saturday — the day you hit harder. That is not a coincidence, it is the whole
point of the calendar.

**The loop it produces**

```
talk to the guide  ->  he names a dungeon and walks to the dock
buy the ticket at Kami Mart (or take it off a boss)
hand it to the collector at the dock  ->  one stamped trip
wait for the day the boat runs
sail  ->  clear the dungeon  ->  the boss stamps the next route
       -> the way home is free                    |
                    every dungeon cleared --------+-> the boat offers "sail home"
                                                       |
                                                   the ending
```

### Add a dungeon to the boat

Nothing here is code.

1. **Make the map.** Either paint one by hand (see *Add a dungeon map*) or add
   an entry to `tools/build_dungeon_map.gd` and run it to get a room-and-
   corridor skeleton you then edit. Mini dungeons are a handful of rooms;
   major ones are close to world-map size.
2. **Put a boat dock in it.** An `EventMarker` on the arrival tile, `kind` =
   `Boat`, `Dock Of` = the dungeon's id. That is how you get home again, and
   the boat never offers to sail you to the dock you are standing on. Coming
   home is free — you only need a stamped pass to leave the port, so a dungeon
   dock needs no collector.
3. **Put a boss in it.** A `MonsterMarker`, `monster` = `Boss`, `Boss Dungeon
   Id` = this dungeon's id, `Reward Ticket` = the `ticket_id` of the route it
   opens (leave empty if it opens nothing).
4. **Register the map.** `main.tscn` → GamePanel → **Map Scenes**. Do the same
   in `tests/SmokeTest.tscn` so the tests see it too. You do not need to note
   where in the list it landed — see step 6.
5. **Write the `DungeonInfo`.** Copy `assets/data/dungeons/mushroom_cave.tres`.
   Set `id` (never rename one after a save exists — saves look dungeons up by
   id), `display_name`, `scale`, `sail_days`, `ticket_id`, `ticket_price`,
   `unlocked_by`, and a `hint` in character. Leave `map_index`,
   `arrive_col` and `arrive_row` alone.
6. **Join the two.** Drag the `DungeonInfo` into the map root's **Dungeon Info**
   slot. That is what fills in `map_index` (wherever the scene sits in Map
   Scenes) and the arrival tile (wherever the Boat marker is), at load time,
   every time — so reordering the map list or moving the dock can never leave
   them stale. Then add the resource to `main.tscn` → GamePanel → **Dungeons**,
   and the same in `tests/SmokeTest.tscn`.
7. **Point a guide at it.** An `NpcMarker` with `npc` = `OldMan`, `Guide
   Dungeon Id` = the new id, and **Guide Target** dragged onto the port's Boat
   dock marker. The port already has a collector (`npc` = `TicketMan`); he
   takes tickets for every route, so a new destination needs no new one.
8. **Run the tests.** `godot --headless --path . res://tests/SmokeTest.tscn`.
   They check every arrival tile is walkable, every id is unique and every
   `map_index` points at a real map, which catches the three mistakes that are
   easy to make here.

The ending needs no updating: it fires when every non-victory, non-home-port
dungeon in the list is cleared, so adding a dungeon automatically makes the
ending harder to reach.

### Mini dungeons and major dungeons

`DungeonInfo.scale` is a label — `mini` or `major` — shown on the boat menu so
the player knows what they are committing to. It changes nothing mechanically;
it is there so a player with twenty minutes can pick accordingly. Keep minis to
one idea and one gimmick, and let majors be the ones that need a plan and a day
of the week.

---

## Levelling and difficulty

The shape of the game's numbers, and why they are what they are.

**The exp curve is a power of the level**, not a multiplier:

```
total exp to reach level N  =  2 x N^2.5
```

| level | 2 | 5 | 10 | 15 | 20 |
|---|---|---|---|---|---|
| total exp | 11 | 112 | 632 | 1743 | 3578 |
| that level alone | 11 | 48 | 146 | 276 | 431 |

Each level costs a little more than the last and no level costs twice the
previous one — both checked by the test suite. The Java version tripled the
requirement every level while handing out 250 exp for one monster, so a single
kill could carry a new player three levels and nothing after that was reachable.

**Attack is strength plus the weapon, not strength times the weapon.**
Multiplying meant every level was multiplied by the weapon as well, which is why
everything died in one hit by level 5. Added, the Kami no Bokken is worth four
levels of strength and stays worth that.

**The ladder.** Each rung is a tier, and a tier is a place:

| | where | meet at | hits to kill | touches to die | exp |
|---|---|---|---|---|---|
| Slime | world map | lv 1 | 3 | 6 | 6 |
| Snome | world map | lv 2 | 3 | 8 | 9 |
| Kamijack | Mushroom Cave | lv 6 | 6 | 6 | 25 |
| Shadow Katsu | Shadow Deep | lv 11 | 10 | 4 | 60 |
| Cave Guardian | boss | lv 7 | 20 | 4 | 150 |
| Deep Guardian | boss | lv 14 | 20 | 4 | 400 |

Those are the numbers the test suite asserts, measured through the real damage
code at the level the player is expected to arrive at. The bands come from the
games this one is built after: trash dies in about three hits, a real enemy in
six, an elite in ten, a boss in twenty; and anything can kill you in four to
eight touches, so no fight is ever safe to stand still in.

**Clearing the world map once is worth 190 exp, which is level 6.** That is the
intended pace: the first area levels you enough to survive the first dungeon,
and the dungeon levels you enough for the next.

**Damage has a floor of 1.** A monster whose defence beat your attack used to
take literally nothing, with no feedback to say so — you could swing at a
Kamijack all day at level 1. Now everything can be chipped, slowly, which turns
an invisible wall into a bad idea the player can feel.

Where to change things: the curve and the per-level gains are exported on
`PlayerStats` (`assets/data/player.tres`); monster numbers are in
`assets/data/monsters/*.tres`; a boss takes its own stat sheet, dropped onto its
`MonsterMarker`.

---

## The three classes

The class screen used to be three names that changed almost nothing: one handed
you a weapon and the other two handed you the Boots. Now a class is a resource
in `assets/data/classes/`, and the title screen builds its menu from whatever is
in GamePanel's **Player Classes** list.

| | Samurai | Ninja | Zilla |
|---|---|---|---|
| Starts with | Kami no Bokken | Kami no Bokken, +3 mana, +10 ammo | Kami Axe |
| Melee | ×1.15 | ×0.75, ignores 2 armour | ×1.0, ×1.4 with the axe |
| Swing speed | normal | **35% faster** | normal (the axe is slow) |
| Thrown | ×1.0 | **×1.5** | ×0.75 |
| At night | — | **×1.35 melee** | — |
| Knock-back dealt | ×1.0 | ×0.8 | **×1.6** |
| Knock-back taken | **×0.4** | ×1.0 | ×1.0 |
| Defence | — | — | **+1 flat** |
| Life a level | 2 | 2 | **3** |
| Dexterity | every 2 levels | every 3 | every 2 |
| Walk speed | 4 | **5** | 3 |

Nobody starts with the Boots — they are a thing you find.

**How they actually play.** Damage per second, measured through the real swing
and the real damage code:

| | lv 1 vs Snome | lv 6 vs Kamijack | lv 11 vs Shadow | lv 14 vs Shadow |
|---|---|---|---|---|
| Samurai | 32.7 | 43.6 | 54.5 | 70.9 |
| Ninja | **42.9** | 42.9 | 42.9 | 60.0 |
| Zilla | 30.0 | 38.2 | 46.4 | 57.3 |

The spread never reaches 1.5×, and each one wins somewhere: the Ninja shreds
unarmoured things and owns the night, the Samurai is the steadiest and hardest
to stagger, and Zilla hits hardest per swing, shoves what he hits across the
room, and has half again the health to stand there doing it. The test suite
asserts all of that — including that nobody kills twice as fast as anybody else,
which is the line between a class and a difficulty setting.

**Adding a fourth** is a `.tres` and a line in the Inspector. Nothing else.

---

## The economy

A new game starts with **nothing**. Everything in Kami Mart has to be earned,
and the earning is built the way the games this one is modelled on did it:
monsters are the income, everything else is a bonus.

| Source | Typical | Repeatable? |
|---|---|---|
| Slime | ~1.5 coins | yes |
| Snome | ~4.7 coins | yes |
| Kamijack | ~11 coins | yes |
| Shadow Katsu | ~20 coins | yes |
| A dungeon boss | 60–90 first kill, 15–25 after | yes |
| Chopping a dry tree | ~0.8 coins (40% chance of 1–4) | no |
| Coins lying on the map | 39 coins across the whole world map | no |
| A chest | 10 coins, in the north field | no |

**Clearing the starting map is worth about 135 coins.** Avoiding the dangerous
things — the five Kamijacks and the Shadow — still comes to about 59, which is
the number that matters: it buys the 40 coin boat ticket, or the Tent, with
change. The full sweep does not buy the 210 coin Kami no Bokken, which is the
other end of the curve. The test suite checks both ends, so a change to a drop
table that breaks the shop shows up immediately.

**Monsters come back when you re-enter a map.** Walking through a door, or
sailing anywhere, rebuilds that map's monsters from its markers. That is the
loop: clear an area, step out, step back, clear it again. Resting at a healing
pool and dying rebuild every map, as before.

Coins on the floor never come back, which is deliberate — they are a reward for
looking around, not a farm. If the game ever feels too rich or too poor, the
dials in order of bluntness are: the drop tables in `scripts/monster/MON_*.gd`,
the `coin_value` on scattered `ObjectMarker`s, and the `price` in each
`scripts/object/OBJ_*.gd`.

---

## Recipes

Each of these uses the framework already in place. `AUTHORING.md` has the
detail on markers, the tile editor and the resource files.

### Add a monster

Cheapest content in the game, and no longer code at all.

1. Drop the sprites in `assets/monster/`.
2. Copy `assets/data/monsters/example_custom.tres` and open it in the Inspector.
   Set life, speed, attack, defence and exp reward; drag two PNGs into **Frames
   Down** (and the other three directions if you have them); pick a
   **Behaviour**; write a **Drops** table.
3. In a map scene, add a `MonsterMarker`, set **Monster** to `From Stats`, drag
   your resource into **Stats**, and put it where you want it.

That is the whole job. The Cave Mushroom in the mushroom cave was made this way.

Only something the four behaviours cannot describe — phases, splitting on death,
summoning — still wants a script: copy `scripts/monster/MON_Slime.gd`, point it
at its own `.tres`, add a line to `EntityGenerator.get_monster()` and an entry
to `MonsterMarker`'s list.

### Add a boss

`scripts/monster/MON_Boss.gd` is the base: six times the health, two phases
(keeps its distance above half health, charges below it), and on death it marks
its dungeon cleared and hands over the next ticket.

1. Place a `MonsterMarker`, set `monster` to `Boss`, and fill in `Boss Dungeon
   Id` and `Reward Ticket`. That is a working boss.
2. For one that plays differently, copy `MON_Boss.gd`, give it its own `.tres`
   and sprites, and override `set_action()`. `MON_Snome.gd` shows how to shoot.
   Add it to `EntityGenerator.get_monster()` and to `MonsterMarker`'s list.
3. Keep `check_drop()` — that is what clears the dungeon. If you override it,
   call `super()`.

### Add a dungeon map

A generator does the tedious part: add an entry to `tools/build_dungeon_map.gd`
and run

```
godot --headless --path . --script tools/build_dungeon_map.gd
```

for a connected room-and-corridor map with a dock, a boss, monsters and chests
already placed. It is an ordinary scene afterwards — open it and change whatever
you like. **Re-running overwrites it**, so once you start editing by hand, take
the entry out of the script.

To paint one from scratch instead:

1. `Scene → New Scene → 2D Scene`, name it after the dungeon, save into
   `scenes/maps/`.
2. Attach `scripts/authoring/DungeonMap.gd` to the root and press
   **Set up this map**. That makes the `Tiles` layer with the right tile set
   and all five group nodes, spelled the way `TileManager` and `AssetSetter`
   look them up.
3. Paint with the TileMap editor. Tick `collision` in the TileSet on anything
   solid — see `AUTHORING.md → Which tiles block movement` — then press
   **Paint the border** so the camera never shows void past the edge.
4. Place monsters, objects and NPCs with their markers, and a
   `PlayerStartMarker` if the player can arrive on foot.
5. Open `main.tscn`, select `GamePanel`, and add the scene to `map_scenes`.
6. Link it up: put an `EventMarker` set to `ChangeMap` on the entrance tile of
   the map it leads from, and drag your new `.tscn` into its **Target Scene**.
   Put a matching one on the arrival tile pointing back.
7. Press **Check this map** and fix whatever it lists.

For a boat destination, also make a `DungeonInfo` in `assets/data/dungeons/`,
drop it into the root's **Dungeon Info** slot, put a `Boat` EventMarker on the
pier with Dock Of = the dungeon's id, and add the resource to
**GamePanel → Dungeons**. Its map number and arrival tile are read off the
scene, so there are no indices to keep in step.

`DUNGEON_CHEATSHEET.md` is the one-page version of all of this.

### Add an item

No code, the same way a monster is no code.

1. Sprite into `assets/objects/`.
2. Copy `assets/data/items/example_weapon.tres` (or `example_consumable.tres`)
   and open it in the Inspector. Set the name, the price, the description, and
   either the weapon/shield numbers or the effect flags — heal, restore mana,
   cure the curse, rest, unlock running. Healing takes a flat amount *and* a
   share of your maximum, so a potion does not become worthless at level 15.
3. Add it to `main.tscn → GamePanel → Items` and to `tests/SmokeTest.tscn`, so
   a saved bag can find it again by name.
4. Place it with an `ObjectMarker` set to **From Stats**, put it in a chest, put
   it on the shop's shelf, or have an NPC hand it over.

Only an item whose effect is a new *rule* rather than a new number still wants a
script: copy the closest `scripts/object/OBJ_*.gd`, add a line to
`EntityGenerator.get_object()` and an entry to `ObjectMarker`'s list.

### Add a character

1. Sprites into `assets/npc/`. Two frames per direction; one direction is
   enough to start.
2. Copy `assets/data/npcs/example_villager.tres`. Set the name, the walk speed
   and how restless they are, then write the **Conversations** — one
   `NpcDialogue` per exchange. Talking moves forward one each time and stops on
   the last, so three conversations is a character who has something new to say
   twice and then settles.
3. Optionally give them a **Gift**: an `ItemStats` handed over the first time
   you talk to them.
4. Place them with an `NpcMarker` set to **From Stats**.

Only a character whose talking *does* something — opens a shop, takes a ticket,
leads you somewhere — still wants a script in `scripts/entity/`.

### Add a key item and a locked door

1. Make the key as an item, above. Give it a name you can test against.
2. The door already exists: `OBJ_Door.gd` plus `InteractiveTileMarker`.
3. For the final door, check for all three keys rather than one. That check
   lives in the door's interaction code.

### The objective tracker  ✅ built

`QuestLog` holds three things: tickets, cleared dungeons, and whichever dungeon
a guide last pointed you at. `objective_text()` works the line out from those
rather than tracking a stage number, so it cannot fall out of step with what the
player has actually done. The pause screen prints it, and a guide NPC sets
`current_target` when he talks to you.

To change what it says, edit `objective_text()` in
`scripts/data/QuestLog.gd` — it is twenty lines and reads top to bottom in
priority order.

### The ending  ✅ built

Sailing home with every dungeon cleared sets `ENDING_STATE`, and
`UI.draw_ending_screen()` draws the results: level, coins, dungeons cleared. It
also calls `WebScore.post_progress(level, coin)`, so finishing the game in the
browser posts to the high-score board on the website.

The victory route is `assets/data/dungeons/victory.tres`, with `is_victory`
ticked. `BoatService` hides it until `QuestLog.all_cleared()` is true, so it
appears on the timetable exactly when the game is finishable.

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
- **A general quest system.** `QuestLog` is three arrays and it answers every
  question the boat, the NPCs and the ending need to ask. Objectives with
  sub-objectives and a dependency graph would be more code than content.
- **More classes.** Three is plenty until the three that exist play
  differently, which is content, not code.
- **More systems.** There are already more mechanics here than content that
  uses them. Crafting, weather, fishing — all of it can wait until the game has
  an ending.

## What to build next, in order

1. **Design the Mushroom Cave.** The generated layout is a skeleton — repaint
   it, give the boss a script and a reason to exist, put something behind a
   locked door.
2. **Give the boss fights a shape.** One gimmick each: a boss that only takes
   damage after a parry, one that summons, one that is genuinely easier on
   Saturday.
3. **Design the Shadow Deep**, bigger, with a mid-point and a shortcut back.
4. **Two or three mini dungeons** hung off the world map (no boat needed) so
   there is something to do between sailings.
5. **NPC dialogue that reacts** to `quest.cleared` — the cheapest way to make
   the world feel like it noticed.

---

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
