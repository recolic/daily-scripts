# created by GitHub Copilot
set -euo pipefail
[[ -f /.dockerenv && -d /kit ]] || { printf 'Run only in the documented disposable Docker container.\n' >&2; exit 1; }
packages=(mutter48 gnome-session48 gnome-shell48 gdm50)
build_uid=$(stat -c %u /kit)
[[ $build_uid != 0 ]] || { printf 'The kit must belong to an unprivileged host user.\n' >&2; exit 1; }
id builder &>/dev/null || useradd -m -u "$build_uid" builder
mkdir -p /kit/.current
chown builder:builder /kit/.current
printf '%s\n' 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' > /etc/pacman.d/mirrorlist
mapfile -t dependencies < <(awk '$1 ~ /^(depends|makedepends|checkdepends)$/ { print $3 }' /kit/*/.SRCINFO | grep -Ev '^(gnome-shell|gnome-session|mutter|libmutter-16\.so)([<=>]|$)' | sort -u)
pacman -Syu --needed --noconfirm base-devel "${dependencies[@]}" python-dbusmock
rm -f /var/cache/pacman/pkg/*.pkg.tar.*
printf '%s\n' '# created by GitHub Copilot' 'source /etc/makepkg.conf' 'SRCDEST="$GNOME48_SOURCE_DIR"' 'MAKEFLAGS="-j${GNOME48_JOBS:-6}"' 'OPTIONS=("${OPTIONS[@]/#debug/!debug}")' > /tmp/gnome48-makepkg.conf

for package_name in "${packages[@]}"; do
  build_dir="/kit/.current/$package_name"
  mkdir -p "$build_dir"
  recipe_changed=true
  if cmp -s "/kit/$package_name/PKGBUILD" "$build_dir/PKGBUILD"; then recipe_changed=false; fi
  cp "/kit/$package_name/PKGBUILD" "$build_dir/"
  for patch_file in /kit/"$package_name"/*.patch; do [[ ! -f $patch_file ]] || cp "$patch_file" "$build_dir/"; done
  for install_file in /kit/"$package_name"/*.install; do [[ ! -f $install_file ]] || cp "$install_file" "$build_dir/"; done
  chown -R builder:builder "$build_dir"
  mapfile -t artifacts < <(runuser -u builder -- env GNOME48_SOURCE_DIR="/kit/$package_name" makepkg --dir "$build_dir" --config /tmp/gnome48-makepkg.conf --packagelist)
  [[ ${#artifacts[@]} == 1 ]] || { printf 'Expected one package from %s.\n' "$package_name" >&2; exit 1; }
  if $recipe_changed || [[ ! -f ${artifacts[0]} ]]; then
    runuser -u builder -- env GNOME48_SOURCE_DIR="/kit/$package_name" GNOME48_JOBS="${GNOME48_JOBS:-6}" makepkg --dir "$build_dir" --config /tmp/gnome48-makepkg.conf --holdver --log --noconfirm --force
  fi
  pacman -U --needed --noconfirm "${artifacts[0]}"
done

for binary in /usr/bin/gnome-shell /usr/bin/mutter /usr/bin/gdm /usr/lib/gnome-session-binary; do ldd "$binary"; done | tee /tmp/gnome48-linkage.log
if grep -q 'not found' /tmp/gnome48-linkage.log; then printf 'Unresolved library dependency.\n' >&2; exit 1; fi
gnome-shell --version
gnome-session --version
gdm --version
env GI_TYPELIB_PATH=/usr/lib/mutter-16 LD_LIBRARY_PATH=/usr/lib/mutter-16 gjs -c 'imports.gi.versions.Meta = "16"; imports.gi.versions.Clutter = "16"; for (const name of ["Meta", "Clutter", "Gdm"]) print(imports.gi[name]);'
glib-compile-schemas --strict --dry-run /usr/share/glib-2.0/schemas
printf '\nCurrent-Arch builds, library resolution, typelibs, and schema checks passed.\n'
bash /kit/smoke-current.sh