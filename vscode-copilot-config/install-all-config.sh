#!/usr/bin/env bash
set -e

for dir in "$HOME"/.config/Code*; do
  [[ -d $dir/User ]] || continue

  echo "installing vscode config for $dir ..."

  for name in mcp settings; do
    target="$HOME/sh/.vscode/_$name.json"
    if [[ $name == settings && ${dir##*/} == Code_code* ]]; then
      target="$HOME/sh/.vscode/_settings_extra.json"
    fi

    [[ -f $target ]] || { printf 'Missing: %s\n' "$target" >&2; exit 1; }
    ln -sfnT -- "$target" "$dir/User/$name.json"
  done
done

