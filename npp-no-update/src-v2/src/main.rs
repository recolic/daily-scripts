#![cfg_attr(not(test), windows_subsystem = "windows")]

use std::env;
use std::fs::create_dir_all;
use std::path::Path;
use std::process::Command;
use std::{error::Error, fs, io::Cursor};

use quick_xml::events::Event;
use quick_xml::events::{BytesStart, BytesText};
use quick_xml::Reader as XmlReader;
use quick_xml::Writer as XmlWriter;

fn main() -> Result<(), Box<dyn Error>> {
    let dir = Path::new(&env::var("temp")?).join(env!("CARGO_PKG_NAME"));
    create_dir_all(&dir)?;

    let npp_dir = Path::new(&env::var("AppData")?).join("Notepad++");
    create_dir_all(&npp_dir)?;
    let npp_config = npp_dir.join("config.xml");
    if npp_config.exists() {
        disable_update(&npp_config)?;
    } else {
        fs::write(npp_config, include_bytes!("../config.xml"))?;
    }

    let installer_path = dir.join("notepad++.exe");
    let npp_exe = include_bytes!("../npp.Installer.exe");
    fs::write(&installer_path, npp_exe)?;
    Command::new(installer_path).spawn()?.wait()?;
    Ok(())
}

fn disable_update(path: &Path) -> Result<(), Box<dyn Error>> {
    let xml = fs::read_to_string(&path)?;
    let mut reader = XmlReader::from_str(&xml);
    reader.trim_text(false);

    let mut writer = XmlWriter::new(Cursor::new(Vec::new()));
    let mut is_target = false;

    loop {
        match reader.read_event()? {
            Event::Start(start) if start.name().as_ref() == b"GUIConfig" => {
                let name = start
                    .attributes()
                    .flatten()
                    .find(|a| a.key.as_ref() == b"name")
                    .unwrap();
                if name.value.as_ref() != b"noUpdate" {
                    writer.write_event(Event::Start(start))?;
                } else {
                    is_target = true;
                    let mut no_update = BytesStart::new("GUIConfig");
                    no_update.push_attribute(("name", "noUpdate"));
                    no_update.push_attribute(("intervalDays", "1145141919"));
                    no_update.push_attribute(("nextUpdateDate", "99991231"));
                    writer.write_event(Event::Start(no_update))?;
                }
            }
            Event::Text(_) if is_target => {
                writer.write_event(Event::Text(BytesText::new("yes")))?;
                is_target = false;
            }
            Event::Eof => break,
            e => writer.write_event(e)?,
        }
    }

    let output = writer.into_inner().into_inner();
    fs::write(&path, output)?;

    Ok(())
}
