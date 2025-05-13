rustc main.rs --crate-name old_backup_clean --out-dir . --target x86_64-unknown-linux-gnu -C target-feature=+crt-static && strip old_backup_clean && mv old_backup_clean ../old-backup-clean.exe
