#!/usr/bin/env sh
set -eu

src_dir="${HOME}/.local/src/logiops"
build_dir="${HOME}/.local/src/logiops/build-system"
prefix="${HOME}/.local/opt/logiops-system"

mkdir -p "$(dirname "$src_dir")"

if [ ! -d "$src_dir/.git" ]; then
  git clone --depth 1 https://github.com/PixlOne/logiops.git "$src_dir"
else
  git -C "$src_dir" pull --ff-only
fi

mkdir -p "$build_dir" "$prefix"
cd "$build_dir"
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix" ..
cmake --build . -j"$(getconf _NPROCESSORS_ONLN)"
install -Dm755 "$build_dir/logid" "$prefix/bin/logid"
install -Dm644 "$build_dir/pizza.pixl.LogiOps.conf" \
  "$prefix/share/dbus-1/system.d/pizza.pixl.LogiOps.conf"
