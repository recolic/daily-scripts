```sh
cd /home/recolic/sh/aur-gnome-48-kit
sudo docker run --name gnome48-validation --memory=12g --memory-swap=12g --cpus=6 --pids-limit=512 \
  --rm -v "$PWD:/kit:rw" archlinux:base-devel bash /kit/build-current.sh

sudo pacman -U ./mutter48/*.tar.zst ./gnome-session48/*.tar.zst gnome-shell48/*.tar.zst gdm50/*.tar.zst
## sudo cp /etc/pam.d/gdm-password.pacsave /etc/pam.d/gdm-password
```
