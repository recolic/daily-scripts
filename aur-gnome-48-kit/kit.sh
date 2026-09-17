# created by GitHub Copilot
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
packages=(mutter48 gnome-session48 gnome-shell48 gdm50)

srcinfo() {
  printf '# created by GitHub Copilot\n'
  makepkg --dir "$1" --printsrcinfo
}

preflight() {
  local package_name missing status=0
  local -a dependencies
  for package_name in "${packages[@]}"; do
    mapfile -t dependencies < <(makepkg --dir "$package_name" --printsrcinfo | awk '$1 ~ /^(depends|makedepends|checkdepends)$/ { print $3 }' | sort -u)
    printf '\n%s:\n' "$package_name"
    if missing=$(pacman -T "${dependencies[@]}"); then printf '  All build dependencies installed.\n'; else printf '%s\n' "$missing"; status=1; fi
  done
  return "$status"
}

case "${1:-check}" in
  check)
    for package_name in "${packages[@]}"; do bash -n "$package_name/PKGBUILD"; diff -u "$package_name/.SRCINFO" <(srcinfo "$package_name"); done
    printf 'Recipe syntax and .SRCINFO are consistent.\n'
    ;;
  metadata)
    for package_name in "${packages[@]}"; do srcinfo "$package_name" > "$package_name/.SRCINFO"; done
    ;;
  preflight) preflight ;;
  sources)
    for package_name in "${packages[@]}"; do makepkg --dir "$package_name" --verifysource --noconfirm; done
    ;;
  build)
    preflight
    for package_name in "${packages[@]}"; do makepkg --dir "$package_name" --log --noconfirm; done
    ;;
  repo)
    archives=()
    for package_name in "${packages[@]}"; do
      mapfile -t candidates < <(makepkg --dir "$package_name" --packagelist | grep -v '/[^/]*-debug-')
      [[ ${#candidates[@]} == 1 ]] || { printf 'Expected one main archive for %s.\n' "$package_name" >&2; exit 1; }
      archive=".current/$package_name/${candidates[0]##*/}"
      [[ -f $archive ]] || { printf 'Missing current-Arch build: %s\n' "$archive" >&2; exit 1; }
      archives+=("$archive")
    done
    mkdir -p .repo
    for archive in "${archives[@]}"; do cp "$archive" .repo/; done
    repo-add .repo/gnome48.db.tar.gz "${archives[@]}"
    ;;
  *) printf 'Usage: bash kit.sh {check|metadata|preflight|sources|build|repo}\n' >&2; exit 2 ;;
esac