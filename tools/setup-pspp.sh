#!/bin/sh
set -eu
# Optional, isolated macOS development oracle. Never a product dependency.
root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root_dir"
mkdir -p .dev/sources
if [ ! -f .dev/sources/pspp.tar.gz ]; then curl --fail --location https://mirrors.kernel.org/gnu/pspp/pspp-2.0.1.tar.gz --output .dev/sources/pspp.tar.gz; fi
python3.12 - <<'PY'
from pathlib import Path
import hashlib,json
p=Path('.dev/sources/pspp.tar.gz')
manifest=Path('docs/development-sources.json')
expected=json.loads(manifest.read_text())['pspp-2.0.1.tar.gz']['sha256']
assert hashlib.sha256(p.read_bytes()).hexdigest()==expected,'PSPP source hash mismatch'
PY
if [ ! -d .dev/sources/pspp-2.0.1 ]; then tar -xzf .dev/sources/pspp.tar.gz -C .dev/sources; fi
if [ ! -d .dev/pspp-deps ]; then conda create -y -p "$root_dir/.dev/pspp-deps" --file docs/pspp-conda-explicit.lock; fi
export PATH="$root_dir/.dev/pspp-deps/bin:$PATH"
export PKG_CONFIG_PATH="$root_dir/.dev/pspp-deps/lib/pkgconfig"
export CPPFLAGS="-I$root_dir/.dev/pspp-deps/include"
export LDFLAGS="-L$root_dir/.dev/pspp-deps/lib -Wl,-rpath,$root_dir/.dev/pspp-deps/lib"
cd .dev/sources/pspp-2.0.1
./configure --prefix="$root_dir/.dev/pspp" --without-gui --without-perl-module --disable-nls
make -j4
make install
"$root_dir/.dev/pspp/bin/pspp" --version
