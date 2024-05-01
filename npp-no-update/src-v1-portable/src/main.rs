use std::{error::Error, fs, io::Cursor};

use quick_xml::events::BytesStart;
use quick_xml::events::Event;
use quick_xml::Reader as XmlReader;
use quick_xml::Writer as XmlWriter;

const TARGET_DIR: &str = "./notepad++";

fn main() -> Result<(), Box<dyn Error>> {
    let npp_7z = include_bytes!("../npp.portable.7z");
    let cursor = Cursor::new(npp_7z);
    sevenz_rust::decompress(cursor, TARGET_DIR)?;
    disable_update()?;
    Ok(())
}

fn disable_update() -> Result<(), Box<dyn Error>> {
    let path = format!("{TARGET_DIR}/config.xml");
    let xml = fs::read_to_string(&path)?;
    let mut reader = XmlReader::from_str(&xml);
    reader.trim_text(false);

    let mut writer = XmlWriter::new(Cursor::new(Vec::new()));

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
                    let mut no_update = BytesStart::new("GUIConfig");
                    no_update.push_attribute(("name", "noUpdate"));
                    no_update.push_attribute(("intervalDays", "1145141919"));
                    no_update.push_attribute(("nextUpdateDate", "99991231"));
                    writer.write_event(Event::Start(no_update))?;
                }
            }
            Event::Eof => break,
            e => writer.write_event(e)?,
        }
    }

    let output = writer.into_inner().into_inner();
    fs::write(&path, output)?;

    Ok(())
}
