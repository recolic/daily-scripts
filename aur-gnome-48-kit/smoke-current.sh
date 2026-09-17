# created by GitHub Copilot
set -euo pipefail
[[ -f /.dockerenv && -d /kit ]] || { printf 'Run only in the disposable validation container.\n' >&2; exit 1; }

if [[ ${1:-} == session ]]; then
  gnome-shell --headless --wayland --no-x11 --virtual-monitor=1280x720 > /kit/.current/smoke.log 2>&1 &
  shell_pid=$!
  trap 'kill "$shell_pid" 2>/dev/null || true; wait "$shell_pid" 2>/dev/null || true' EXIT
  python - <<'PY'
import sys
from gi.repository import Gio, GLib

loop = GLib.MainLoop()
log_file = Gio.File.new_for_path('/kit/.current/smoke.log')
ready = failed = False

def inspect(*args):
    global ready, failed
    if not log_file.query_exists(None): return
    text = log_file.load_contents(None)[1].decode(errors='replace')
    ready = 'GNOME Shell started at' in text
    failed = 'Execution of main.js threw exception' in text
    if ready or failed: loop.quit()

monitor = log_file.monitor_file(Gio.FileMonitorFlags.NONE, None)
monitor.connect('changed', inspect)
GLib.timeout_add_seconds(30, loop.quit)
inspect()
if not (ready or failed): loop.run()
if not ready:
    print(log_file.load_contents(None)[1].decode(errors='replace'))
    sys.exit(1)
PY
  gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.freedesktop.DBus.Properties.Get org.gnome.Shell ShellVersion
  kill -0 "$shell_pid"
  printf 'Headless GNOME Shell owns its D-Bus name and answers the ShellVersion property.\n'
else
  dbus-uuidgen --ensure=/etc/machine-id
  mkdir -p /run/dbus
  rm -f /run/dbus/system_bus_socket
  dbus-daemon --system --fork --nopidfile
  python -m dbusmock --system -t logind > /kit/.current/logind-mock.log 2>&1 &
  mock_pid=$!
  trap 'kill "$mock_pid" 2>/dev/null || true' EXIT
  gdbus wait --system --timeout 10 org.freedesktop.login1
  install -d -o builder -g builder -m 700 /tmp/gnome48-runtime
  runuser -u builder -- env XDG_RUNTIME_DIR=/tmp/gnome48-runtime XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=GNOME LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe dbus-run-session -- bash /kit/smoke-current.sh session
fi