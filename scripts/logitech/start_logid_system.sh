#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)

logid_bin="${HOME}/.local/opt/logiops-system/bin/logid"
dbus_conf_src="${HOME}/.local/opt/logiops-system/share/dbus-1/system.d/pizza.pixl.LogiOps.conf"
config_path="${repo_root}/logiops/etc/logid.cfg"

if [ ! -x "$logid_bin" ]; then
  echo "logid no está compilado en ${logid_bin}" >&2
  echo "Ejecuta primero: ${repo_root}/scripts/logitech/build_logiops_system.sh" >&2
  exit 1
fi

if [ ! -f "$dbus_conf_src" ]; then
  echo "No existe la política DBus generada en ${dbus_conf_src}" >&2
  echo "Ejecuta primero: ${repo_root}/scripts/logitech/build_logiops_system.sh" >&2
  exit 1
fi

exec pkexec sh -c '
set -eu
install -Dm644 "$1" /etc/dbus-1/system.d/pizza.pixl.LogiOps.conf
if [ -f /etc/systemd/system/logid.service ]; then
  systemctl disable --now logid.service >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/logid.service
  systemctl daemon-reload
fi
existing=$(ps -eo pid=,ppid=,args= | awk '"'"'$0 ~ /\\.local\\/opt\\/logiops-system\\/bin\\/logid/ { print; exit }'"'"')
if [ -n "$existing" ]; then
  printf "%s\n" "$existing"
  exit 0
fi
setsid "$2" -c "$3" -v info >/tmp/logid-detached.log 2>&1 </dev/null &
echo $! >/tmp/logid-detached.pid
sleep 3
ps -p "$(cat /tmp/logid-detached.pid)" -o pid=,ppid=,comm=,user=,args= >/dev/null
ps -p "$(cat /tmp/logid-detached.pid)" -o pid=,ppid=,comm=,user=,args=
' sh "$dbus_conf_src" "$logid_bin" "$config_path"
