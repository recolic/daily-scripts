mod path;
use std::{
    collections::{BTreeMap, HashMap},
    env,
    error::Error,
    fs,
    path::PathBuf,
};

use path::BackupFile;

// keep last N archives
const KEEP_LAST_N_ARCHIVES: usize = 3;
// keep last N monthly archives (the first archive of a month)
const KEEP_LAST_N_MONTHS: usize = 3;
// keep last N annually archives (the first archive of a year)
const KEEP_LAST_N_YEARS: usize = 6;

fn main() -> Result<(), Box<dyn Error>> {
    let target_dir = env::args().nth(1).ok_or_else(|| {
        let my_path = env::args().nth(0).unwrap();
        format!("{my_path} <TARGET DIR>")
    })?;
    let target_dir = PathBuf::from(target_dir);

    target_dir
        .is_dir()
        .then_some(())
        .ok_or("target dir should be a directory")?;

    let mut target_backupfiles: HashMap<String, Vec<BackupFile>> = HashMap::new();
    for backup_file in target_dir
        .read_dir()?
        .filter_map(Result::ok)
        .map(|e| e.path())
        .filter_map(BackupFile::new)
    {
        target_backupfiles
            .entry(backup_file.target.clone())
            .or_default()
            .push(backup_file);
    }

    for backup_files in target_backupfiles.into_values() {
        let delete_list = backups_to_delete(backup_files.into_iter())?;
        for path in delete_list.map(|bf| bf.path) {
            println!("Delete: {}", path.to_string_lossy());
            if let Err(e) = fs::remove_file(&path) {
                println!(
                    "Error occured when deleting {}: {e}",
                    path.to_string_lossy()
                )
            }
        }
    }

    Ok(())
}

fn backups_to_delete(
    backup_files: impl Iterator<Item = BackupFile>,
) -> Result<impl Iterator<Item = BackupFile>, Box<dyn Error>> {
    // year -> backup files
    let mut backfile_map: BTreeMap<u32, Vec<BackupFile>> = BTreeMap::new();
    for (year, backup_file) in backup_files.map(|back| (back.year, back)) {
        backfile_map.entry(year).or_default().push(backup_file);
    }
    // sort backup files by timestamps in filename
    backfile_map.iter_mut().for_each(|(_, backup_files)| {
        backup_files.sort();
    });

    // keep at most `KEEP_LAST_N_MONTHS` annually backup
    backfile_map
        .iter_mut()
        .rev()
        .take(KEEP_LAST_N_YEARS)
        .for_each(|(_, b)| {
            b[0].keep = true;
        });

    let mut monthly_backups: BTreeMap<_, &mut BackupFile> = BTreeMap::new();
    for (year, backups) in backfile_map.iter_mut() {
        for backup_file in backups.iter_mut().rev() {
            // for every month only the first archive will be kept,
            // as `insert`` will replace previous value.
            monthly_backups.insert((year, backup_file.month), backup_file);
        }
    }
    // keep at most `KEEP_LAST_N_MONTHS` monthly archives
    monthly_backups
        .into_iter()
        .rev()
        .take(KEEP_LAST_N_MONTHS)
        .for_each(|(_, b)| b.keep = true);

    // keep last N archives
    backfile_map
        .iter_mut()
        .map(|(_, b)| b)
        .flatten()
        .rev()
        .take(KEEP_LAST_N_ARCHIVES)
        .for_each(|b| b.keep = true);

    Ok(backfile_map
        .into_iter()
        .map(|(_, files)| files.into_iter())
        .flatten()
        .filter(|b| b.keep == false))
}
