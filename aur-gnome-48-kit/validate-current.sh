# created by GitHub Copilot
set -euo pipefail
[[ -f /.dockerenv && -d /kit ]] || { printf 'Run only inside the documented disposable Docker container.\n' >&2; exit 1; }
shopt -s nullglob
packages=(mutter48 gnome-session48 gnome-shell48 gdm48)
archives=()
mkdir -p /tmp/gnome48-repo /tmp/gnome48-db /tmp/gnome48-cache
cp -a "${GNOME48_PACMAN_DB:-/var/lib/pacman}/local" /tmp/gnome48-db/
for package_name in "${packages[@]}"; do
  mapfile -t candidates < <(bsdtar -xOf /kit/.repo/gnome48.db.tar.gz "$package_name-*/desc" | sed -n '/^%FILENAME%$/{n;p;}')
  [[ ${#candidates[@]} == 1 ]] || { printf 'Expected exactly one binary archive for %s, found %s.\n' "$package_name" "${#candidates[@]}" >&2; exit 1; }
  archives+=("/kit/.repo/${candidates[0]}")
  ln -s "/kit/.repo/${candidates[0]}" /tmp/gnome48-repo/
done
repo-add /tmp/gnome48-repo/gnome48.db.tar.gz "${archives[@]}" > /tmp/gnome48-repo.log
printf '%s\n' '[options]' 'Architecture = auto' 'DBPath = /tmp/gnome48-db' 'CacheDir = /tmp/gnome48-cache' 'LogFile = /tmp/gnome48-pacman.log' 'SigLevel = Required DatabaseOptional' > /tmp/gnome48-pacman.conf
printf '%s\n' '[gnome48]' 'SigLevel = Optional TrustAll' 'Server = file:///tmp/gnome48-repo' '[core]' 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' '[extra]' 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' >> /tmp/gnome48-pacman.conf
printf '%s\n' '[multilib]' 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' >> /tmp/gnome48-pacman.conf
pacman --config /tmp/gnome48-pacman.conf -Sy --noconfirm
if ! pacman --config /tmp/gnome48-pacman.conf -Sup --noconfirm --print-format '%n %v %s' "${packages[@]}" > /tmp/gnome48-plan; then cat /tmp/gnome48-plan; exit 1; fi
cat /tmp/gnome48-plan
awk '{ total += $3; count++ } END { printf "\nTransaction: %d packages, %.1f MiB compressed (including local archives).\n", count, total / 1048576 }' /tmp/gnome48-plan