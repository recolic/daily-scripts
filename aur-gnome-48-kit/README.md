<!-- created by GitHub Copilot -->
# GNOME 48 Kit

Four local AUR-style packages keep Shell 48.5 on otherwise current Arch Linux. Built and smoke-tested against current repositories on 2026-09-16. Not published to AUR. Host GNOME packages have not been replaced.

| Package | Current build | Reason |
| --- | --- | --- |
| mutter48 | 48.5-4 | Shell 48 requires libmutter-16, not current Mutter's ABI. |
| gnome-shell48 | 1:48.5-5 | Your known-working Shell release. |
| gnome-session48 | 48.0-2 | Preserves the GNOME 48 session runtime. |
| gdm50 | 50.3-2 | Current systemd-aware GDM, bridged to the GNOME 48 Shell. |

GDM is optional only if you deliberately switch to another display manager. With this host's existing GDM setup, use all four. GJS, libgdm, settings-daemon, control-center, schemas, and portals remain current repository packages.

## Ready Artifacts

The `.repo/` directory contains the four current-Arch binary packages and `gnome48.db`. It is the upgrade repository. `.current/` contains the matching build trees and logs. Both directories are ignored by git; regenerate binaries when moving the recipes to another machine.

**Do not install archives directly from the four recipe directories for the upgrade.** Those are earlier host-snapshot test builds, linked to old libraries. The current Mutter binary requires `libdisplay-info.so=3-64`; the old host build requires `=2-64`.

## Validation

Passed in a disposable current-Arch container:

- All four packages built with real current dependencies, then installed through pacman inside the container.
- Session defines no tests. Mutter/Shell upstream test suites are disabled, matching the original Arch recipes. GDM 50 is repackaged from a checksum-pinned official Arch archive.
- Executables resolve their dynamic libraries; Meta 16, Clutter 16, and Gdm typelibs load under GJS 1.88.1; installed schemas pass strict validation.
- Shell 48.5 reached startup completion on a 1280x720 headless Wayland monitor with llvmpipe and answered its D-Bus `ShellVersion` property.
- A separate current-repository transaction preview resolved the actual exported packages without dependency overrides.

The smoke test uses a standard mocked logind service because the container is not a booted system. It does **not** establish real GDM/PAM login, locking, suspend, GPU/input behavior, Xwayland, screen sharing, extensions, or the original keybinding-leak reproducer. Missing container services cause warnings. The calendar service also logged a timezone assertion in this minimal container; calendar/timezone behavior needs a real-session check.

A second preview used a read-only copy of this host's actual installed-package database with current core/extra/multilib. It found two unrelated blockers: `lib32-audit` requires `audit=4.0.5`, and `lib32-libcap` requires `libcap=2.76`. Obtain compatible rebuilds or review whether their consumers can be removed before upgrading. No packages were removed. This preview did not include future packages from the custom `recolic-aur` repository or reproduce every host pacman option.

Tested library baseline includes GLib 2.88.3, GJS 1.88.1, libical 4.0.5, libdisplay-info 0.3.0, Pango 1.58.2, libgdm 50.3, settings-daemon 50, and systemd 261.3. Exact dependency versions are recorded in each binary's `.BUILDINFO`.

## Upgrade Procedure

These steps are for the user, not automatically executed by the kit. The host upgrade and replacement of the running desktop still require approval.

1. Create a recoverable system snapshot and verify TTY access. Preserve package caches and the old mirror/pacman configuration. Rolling back only Shell and Mutter cannot undo a full library upgrade.
2. Resolve the host's boot configuration before upgrading: installing build dependencies triggered mkinitcpio errors for missing `/boot/vmlinuz-linux-lts-recolicmpc`. Fontconfig hooks also reported directory errors. These unrelated problems were not changed.
3. Review Arch upgrade news since September 2025, including third-party packages, and resolve the two `lib32-*` dependency blockers above. The current mirror configuration points to `archive.archlinux.org/repos/2025/09/15`; it must be changed to current mirrors for an actual upgrade. Review `IgnorePkg`/`IgnoreGroup` too. Do not perform `pacman -Sy` followed by isolated package installs.
4. Add the following local repository section **before** the official repositories in `/etc/pacman.conf`. Keep it local and trusted: these locally built packages are unsigned. Ensure pacman's download user can traverse the path; otherwise copy the entire `.repo/` directory to a readable location and adjust `Server`.

```ini
[gnome48]
SigLevel = Optional TrustAll
Server = file:///home/recolic/sh/aur-gnome-48-kit/.repo
```

5. From a TTY, request the full upgrade and all four replacements in **one transaction**:

```sh
sudo pacman -Syu gnome48/mutter48 gnome48/gnome-session48 gnome48/gnome-shell48 gnome48/gdm50
```

Review conflicts and removals before confirming. Replacing the four corresponding official packages is expected. Do not accept unrelated desktop removals without investigation; do not use `-Rdd`, `--nodeps`, or blanket `--overwrite`. A successful clean-container transaction is not approval of all third-party packages on this host.

6. Reboot only after the transaction and initramfs generation succeed. Test GDM login, unlock, logout, suspend, settings, native Wayland/Xwayland applications, portals, and your keybinding reproducer. Begin without extensions; re-enable known-compatible versions individually. Keep a TTY and rollback path available.

Different package names prevent ordinary repository upgrades from silently replacing the kit. Accurate versioned `provides` satisfy compatible consumers; conflicts reject the originals. No fake high versions or broad `IgnorePkg` freeze is used. GNOME group installs and AUR-helper prompts still need review.

## Build And Maintain

Run these commands from this directory (they work from fish because Bash scripts are invoked explicitly):

```sh
bash kit.sh check
bash kit.sh preflight
bash kit.sh sources
bash kit.sh build
```

Local builds never install packages or invoke sudo. Install missing build dependencies separately against a consistent repository snapshot. The local recipes accept installed official GNOME 48 dependencies, so host testing does not require replacing the active desktop. Compilation defaults to two jobs; set `GNOME48_JOBS` to override.

For current-Arch rebuilds, use the isolated builder. It reuses verified source caches and saves outputs under `.current/`. The container installs build dependencies and the kit internally, never on the host. Only this kit directory is mounted; no host display, Docker socket, devices, or system bus are exposed.

```sh
sudo docker run --name gnome48-validation --memory=12g --memory-swap=12g --cpus=6 --pids-limit=512 -v "$PWD:/kit:rw" archlinux:base-devel bash /kit/build-current.sh
```

If that container already exists, resume with `sudo docker start -a gnome48-validation`. Successful unchanged archives are reused. Bump `pkgrel` whenever a recipe changes or an ABI rebuild is needed; a reused archive is not a fresh rebuild against newly updated dependencies. Remove/recreate the container for a clean-environment check when appropriate.

After successful builds:

```sh
bash kit.sh metadata
bash kit.sh check
bash kit.sh repo
sudo docker run --rm --read-only --memory=512m --cpus=1 --pids-limit=64 --tmpfs /tmp:rw,nosuid,nodev,size=128m -v "$PWD:/kit:ro" archlinux:base-devel bash /kit/validate-current.sh
```

`repo` exports only archives whose names match the current recipes. `validate-current.sh` downloads sync metadata into temporary storage and previews a full current-Arch transaction; it installs nothing. After validation, `sudo docker rm gnome48-validation` removes the stopped builder and its dependency installation without deleting `.current/` or `.repo/`.

Before each future upgrade, refresh the build/test baseline, review security fixes, and rerun real-session checks after significant library changes. Keeping an old compositor and login manager requires security backports; GNOME 48 is not promised indefinite support. No unattended maintenance has been configured.

Each package directory contains a `.SRCINFO` suitable for AUR submission alongside its recipe and local patches. Publication requires an AUR account, name checks, and separate approval. Do not submit generated source caches or binary packages. Retire this kit once a current GNOME release passes your original regression scenario.

## Compatibility Changes And Provenance

Recipes derive from official Arch tags: [Mutter 48.5-1](https://gitlab.archlinux.org/archlinux/packaging/packages/mutter/-/tree/48.5-1), [Shell 1:48.5-1](https://gitlab.archlinux.org/archlinux/packaging/packages/gnome-shell/-/tree/1-48.5-1), [Session 48.0-1](https://gitlab.archlinux.org/archlinux/packaging/packages/gnome-session/-/tree/48.0-1), and [GDM 48.0-2](https://gitlab.archlinux.org/archlinux/packaging/packages/gdm/-/tree/48.0-2). Documentation subpackages are omitted. Upstream source hashes are retained except the explicitly corrected GVDB pin.

- Mutter: GVDB pin matches the revision requested by 48.5's own wrap file; current `arch-meson` checks this. A compiler feature probe removes a duplicate PangoRenderer cleanup declaration only when Pango provides it. The libdisplay-info SONAME is recorded in binary dependencies.
- Shell: libical 4 callback fix backported from upstream commit `39a8a120dea223f70465c959766e2dd19d3d6204` (MR 4215).
- Shell: GJS 1.85+/GIRepository migration backported from `c8e28918aa96c53333ea7019eb24642b7878b548` (MR 3801), without changing the Mutter ABI. Applied only with new GJS. Binary metadata records the matching GJS version bound; source metadata remains generic. GDM 50's `RegisterSession()` ABI is used when registering the greeter.
- Session: removes the obsolete Wacom service requirement. Session 50 cannot replace it unchanged: its startup units require `org.gnome.Shell@user.service`, and `CanShutdown` changed signature.
- GDM: current GDM 50 is repackaged from the official Arch archive with its BLAKE2 checksum pinned. A small `gnome-session@gnome-login` drop-in requires GNOME Shell's existing systemd target. GDM 48's private D-Bus/session-manager contract is incompatible with current systemd 261.

The initial versions intentionally preserve the user's known-working Shell/Mutter release, not a claim that these are the newest GNOME 48 maintenance releases. Review future upstream fixes individually rather than importing GNOME 49 compositor behavior wholesale.