#!/usr/bin/env bash
set -e

for dir in "$HOME"/.config/Code*; do
  user_dir="$dir/User"
  [[ -d $user_dir ]] || user_dir="$dir/user-data/User"
  [[ -d $user_dir ]] || continue

  echo "installing vscode config for $user_dir ..."

  for name in mcp settings; do
    target="$HOME/sh/vscode-copilot-config/_$name.json"
    if [[ $name == settings && ${dir##*/} == Code_code* ]]; then
      target="$HOME/sh/vscode-copilot-config/_settings_extra.json"
    fi

    [[ -f $target ]] || { printf 'Missing: %s\n' "$target" >&2; exit 1; }
    ln -sfnT -- "$target" "$user_dir/$name.json"
  done
done

if [[ -f "$HOME/sh/AGENTS.md" ]]; then
  echo "installing copilot-instructions..."
  mkdir -p -- "$HOME/.copilot"
  ln -sfnT -- "$HOME/sh/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"
fi

