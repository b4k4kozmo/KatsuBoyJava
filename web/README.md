# Web demo build

Generated output — **do not edit anything in here by hand.** It is rebuilt by
`KatsuBoyGodot/tools/build_web.sh` (or by the `Web demo` GitHub Actions
workflow) from the project in `../KatsuBoyGodot`.

## Trying it locally

```
cd web
python3 -m http.server 8000
```

then open <http://localhost:8000/>.

Opening `index.html` straight off disk as a `file://` URL will **not** work —
browsers refuse to fetch the `.wasm` that way. It needs to come off a server,
any server.

## Rebuilding

```
KatsuBoyGodot/tools/build_web.sh /path/to/godot
```

You need the Godot 4.5.1 **web export templates** installed first: in the
editor, *Editor → Manage Export Templates → Download and Install*, or unzip the
`web_*.zip` files out of `Godot_v4.5.1-stable_export_templates.tpz` into
`~/.local/share/godot/export_templates/4.5.1.stable/`.

## What is in here

| File | |
|---|---|
| `index.html` | the demo page, built from `KatsuBoyGodot/web_shell/index.html` |
| `index.wasm` | the Godot engine, ~37 MB (servers gzip it to about 9 MB) |
| `index.pck` | the game itself: scripts, art, sound, maps |
| `index.js`, `index.audio*.js` | engine loader and audio worklets |

Built with **threads off**, so it works on any plain static host — no
cross-origin isolation headers needed.
