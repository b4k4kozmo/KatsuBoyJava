#!/usr/bin/env bash
# Build the playable web demo into ../web/
#
#   tools/build_web.sh [path/to/godot]
#
# Needs the Godot 4.5.1 web export templates installed
# (Editor -> Manage Export Templates, or download the .tpz and unzip the
#  web_*.zip files into ~/.local/share/godot/export_templates/4.5.1.stable/).
#
# To try it locally afterwards:
#   cd web && python3 -m http.server 8000
# then open http://localhost:8000/ - opening index.html as a file:// URL will
# not work, browsers refuse to fetch the .wasm that way.
set -euo pipefail

GODOT="${1:-godot}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$HERE/../web"

mkdir -p "$OUT"
rm -f "$OUT"/index.*

"$GODOT" --headless --path "$HERE" --export-release "Web" "$OUT/index.html"

echo
echo "Built into $OUT"
du -ch "$OUT"/* | tail -1
