#!/usr/bin/env bash
# Bangun pratinjau web (tanpa rekam suara dan notifikasi) yang bisa dibuka
# langsung di browser tanpa akses ke CDN luar. Hasil: build/web
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build web --release --no-web-resources-cdn --no-source-maps
cd build/web
sed -i 's|<base href="/">||' index.html
rm -f flutter_service_worker.js canvaskit/skwasm* canvaskit/wimp* .last_build_id
find . -name '*.symbols' -delete
python3 - <<'PY'
import re
p = 'flutter_bootstrap.js'
s = open(p).read()
s = re.sub(r"_flutter\.loader\.load\(\{.*?\}\);", "_flutter.loader.load();", s, flags=re.S)
open(p, 'w').write(s)
PY
