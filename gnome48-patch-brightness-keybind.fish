#!/usr/bin/env fish
# created by Gemini 3.8 Flash
set -l base 'org.gnome.settings-daemon.plugins.media-keys'
set -l up_path '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/brightness-up/'
set -l down_path '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/brightness-down/'

# append up_path and down_path to gsettings custom-keybindings list if not already present
python3 -c "import ast, subprocess; s='$base'; u='$up_path'; d='$down_path'; raw=subprocess.check_output(['gsettings', 'get', s, 'custom-keybindings'], text=True).strip(); b=ast.literal_eval(raw) if raw not in ('', '@as []', '[]') else []; [b.append(x) for x in (u, d) if x not in b]; subprocess.check_call(['gsettings', 'set', s, 'custom-keybindings', str(b)])"

gsettings set "$base.custom-keybinding:$up_path" name 'Brightness Up'
gsettings set "$base.custom-keybinding:$up_path" command 'brightnessctl s +4%'
gsettings set "$base.custom-keybinding:$up_path" binding 'XF86MonBrightnessUp'
gsettings set "$base.custom-keybinding:$up_path" enable-in-lockscreen true

gsettings set "$base.custom-keybinding:$down_path" name 'Brightness Down'
gsettings set "$base.custom-keybinding:$down_path" command 'brightnessctl s 4%-'
gsettings set "$base.custom-keybinding:$down_path" binding 'XF86MonBrightnessDown'
gsettings set "$base.custom-keybinding:$down_path" enable-in-lockscreen true

echo "Brightness keys (XF86MonBrightnessUp / XF86MonBrightnessDown) bound to brightnessctl."
