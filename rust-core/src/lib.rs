//! NortInstall Rust core.
//!
//! Собирается в `NortInstallFFI.xcframework` и вызывается из Swift через
//! заголовок `include/NortInstallFFI.h`. Здесь живёт то, что удобнее делать
//! на Rust: разбор IPA, а в будущем — работа с профилями и подписью.

use std::ffi::{c_char, CStr, CString};
use std::io::Read;
use std::panic::{catch_unwind, AssertUnwindSafe};

/// Разбирает Info.plist и embedded.mobileprovision внутри IPA.
/// Возвращает JSON вида
/// `{"name":"…","bundle_id":"…","version":"…","minimum_os":"…",`
/// `"has_provision":true,"team_id":"ABCDE12345"}`
/// либо `{"error": "..."}`. Строку освобождает `ni_free_string`.
///
/// # Safety
/// `path` должен быть валидным C-указателем на строку в UTF-8.
#[no_mangle]
pub unsafe extern "C" fn ni_ipa_info(path: *const c_char) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let path = CStr::from_ptr(path).to_string_lossy().into_owned();
        ipa_info_json(&path)
    }));

    match result {
        Ok(Ok(json)) => to_c_string(json),
        Ok(Err(message)) => to_c_string(format!(r#"{{"error":"{message}"}}"#)),
        Err(_) => to_c_string(r#"{"error":"внутренняя паника rust-core"}"#.to_string()),
    }
}

/// Освобождает строку, возвращённую функциями `ni_*`.
///
/// # Safety
/// Указатель должен быть получен из этого же crate и освобождён ровно один раз.
#[no_mangle]
pub unsafe extern "C" fn ni_free_string(string: *mut c_char) {
    if !string.is_null() {
        drop(CString::from_raw(string));
    }
}

type Archive = zip::ZipArchive<std::fs::File>;

fn ipa_info_json(path: &str) -> Result<String, String> {
    let file = std::fs::File::open(path).map_err(|e| format!("не удалось открыть файл: {e}"))?;
    let mut archive = zip::ZipArchive::new(file).map_err(|e| format!("это не zip/IPA: {e}"))?;

    // Info.plist — обязательная часть IPA
    let plist_index = find_payload_entry(&mut archive, ".app/Info.plist")
        .ok_or("в IPA не найден Payload/*.app/Info.plist")?;
    let raw = read_entry(&mut archive, plist_index)?;
    let info = parse_app_info(&raw)?;

    // embedded.mobileprovision — есть в подписанных сборках; Team ID нужен,
    // чтобы понять, каким аккаунтом подписано приложение
    let provision = find_payload_entry(&mut archive, ".app/embedded.mobileprovision")
        .map(|index| read_entry(&mut archive, index))
        .transpose()?;
    let team_id = provision.as_deref().and_then(team_id_from_provision);

    let mut value = info;
    value["has_provision"] = serde_json::json!(provision.is_some());
    value["team_id"] = serde_json::json!(team_id);

    serde_json::to_string(&value).map_err(|e| format!("сборка JSON не удалась: {e}"))
}

/// Ищет файл вида `Payload/<App>.app/<suffix>` (ровно два слэша, чтобы не
/// зацепить вложенные бандлы PlugIns/Watch).
fn find_payload_entry(archive: &mut Archive, suffix: &str) -> Option<usize> {
    (0..archive.len())
        .filter_map(|i| archive.name_for_index(i).map(|n| (i, n.to_owned())))
        .find(|(_, name)| {
            name.starts_with("Payload/") && name.ends_with(suffix) && name.matches('/').count() == 2
        })
        .map(|(i, _)| i)
}

fn read_entry(archive: &mut Archive, index: usize) -> Result<Vec<u8>, String> {
    let mut entry = archive
        .by_index(index)
        .map_err(|e| format!("не удалось прочитать запись {index}: {e}"))?;
    let mut raw = Vec::new();
    entry
        .read_to_end(&mut raw)
        .map_err(|e| format!("не удалось прочитать запись {index}: {e}"))?;
    Ok(raw)
}

fn parse_app_info(raw: &[u8]) -> Result<serde_json::Value, String> {
    let value = plist::Value::from_reader(std::io::Cursor::new(raw))
        .map_err(|e| format!("Info.plist не разбирается: {e}"))?;
    let dict = value
        .as_dictionary()
        .ok_or("Info.plist не является словарём")?;

    let get = |key: &str| {
        dict.get(key)
            .and_then(plist::Value::as_string)
            .map(str::to_owned)
    };

    Ok(serde_json::json!({
        "name": get("CFBundleDisplayName")
            .or_else(|| get("CFBundleName"))
            .unwrap_or_default(),
        "bundle_id": get("CFBundleIdentifier").unwrap_or_default(),
        "version": get("CFBundleShortVersionString").unwrap_or_default(),
        "minimum_os": get("MinimumOSVersion"),
    }))
}

/// .mobileprovision — это XML-plist в CMS-обёртке (DER). Достаём XML между
/// `<?xml` и `</plist>` и читаем TeamIdentifier.
fn team_id_from_provision(bytes: &[u8]) -> Option<String> {
    let text = String::from_utf8_lossy(bytes);
    let start = text.find("<?xml")?;
    let end = text.rfind("</plist>")? + "</plist>".len();
    let value = plist::Value::from_reader(std::io::Cursor::new(&text[start..end])).ok()?;
    let dict = value.as_dictionary()?;

    dict.get("TeamIdentifier")
        .and_then(plist::Value::as_array)
        .and_then(|teams| teams.first())
        .and_then(plist::Value::as_string)
        .or_else(|| {
            dict.get("Entitlements")
                .and_then(plist::Value::as_dictionary)
                .and_then(|e| e.get("com.apple.developer.team-identifier"))
                .and_then(plist::Value::as_string)
        })
        .map(str::to_owned)
}

fn to_c_string(value: String) -> *mut c_char {
    // null не возвращаем: в худшем случае отдаём JSON с ошибкой
    CString::new(value.replace('\0', " "))
        .unwrap_or_else(|_| CString::new(r#"{"error":"строка с нулевым байтом"}"#).unwrap())
        .into_raw()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;
    use zip::write::SimpleFileOptions;

    const APP_PLIST: &[u8] = br#"<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleDisplayName</key><string>Demo</string>
<key>CFBundleIdentifier</key><string>app.nortinstall.demo</string>
<key>CFBundleShortVersionString</key><string>1.2.3</string>
<key>MinimumOSVersion</key><string>16.0</string>
</dict></plist>"#;

    /// XML-plist внутри «CMS-обёртки» — имитируем реальный .mobileprovision.
    const PROVISION: &[u8] = br#"0FakeCMSHeader<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>TeamIdentifier</key><array><string>ABCDE12345</string></array>
<key>Entitlements</key><dict>
<key>application-identifier</key><string>ABCDE12345.app.nortinstall.demo</string>
</dict>
</dict></plist>0FakeCMSTrailer"#;

    fn build_ipa(name: &str, with_provision: bool) -> String {
        let path = std::env::temp_dir().join(format!("nortinstall-{name}-{}.ipa", std::process::id()));
        let file = std::fs::File::create(&path).unwrap();
        let mut zip = zip::ZipWriter::new(file);
        zip.start_file("Payload/Demo.app/Info.plist", SimpleFileOptions::default())
            .unwrap();
        zip.write_all(APP_PLIST).unwrap();
        if with_provision {
            zip.start_file(
                "Payload/Demo.app/embedded.mobileprovision",
                SimpleFileOptions::default(),
            )
            .unwrap();
            zip.write_all(PROVISION).unwrap();
        }
        zip.finish().unwrap();
        path.to_string_lossy().into_owned()
    }

    #[test]
    fn parses_plist_and_provision() {
        let json = ipa_info_json(&build_ipa("full", true)).unwrap();
        let value: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(value["name"], "Demo");
        assert_eq!(value["bundle_id"], "app.nortinstall.demo");
        assert_eq!(value["version"], "1.2.3");
        assert_eq!(value["minimum_os"], "16.0");
        assert_eq!(value["has_provision"], true);
        assert_eq!(value["team_id"], "ABCDE12345");
    }

    #[test]
    fn parses_unsigned_ipa() {
        let json = ipa_info_json(&build_ipa("unsigned", false)).unwrap();
        let value: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(value["has_provision"], false);
        assert_eq!(value["team_id"], serde_json::Value::Null);
    }

    #[test]
    fn reports_missing_plist() {
        let path = std::env::temp_dir().join(format!("nortinstall-empty-{}.ipa", std::process::id()));
        let file = std::fs::File::create(&path).unwrap();
        let mut zip = zip::ZipWriter::new(file);
        zip.start_file("random.txt", SimpleFileOptions::default()).unwrap();
        zip.write_all(b"hi").unwrap();
        zip.finish().unwrap();

        let error = ipa_info_json(path.to_string_lossy().as_ref()).unwrap_err();
        assert!(error.contains("Info.plist"));
    }
}
