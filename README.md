# NortInstall

**Sideload на iPhone без компьютера** — открытый каркас инсталлера IPA,
вдохновлённый архитектурой [SideInstaller](https://github.com/FrizzleM/SideInstaller):
SwiftUI-приложение + ядро на Rust + веб-страница «установить в один тап».

> ⚠️ **Статус: каркас.** Что-то уже работает, а самые сложные шаги
> (подписание и установка) — честные заглушки с планом в разделе
> [Roadmap](#roadmap). Никаких обещаний «всё ставится» здесь пока нет.

## Что уже работает

| Часть | Статус |
|---|---|
| `web/` — лендинг, секции «Установка / Сертификаты / DNS» и `open.html`, передающая IPA в приложение через `nortinstall://install?url=…` | ✅ работает |
| `web/dns.html` — генератор DNS-профиля: вводите ID конфига NextDNS → страница собирает `NortInstallDNS.mobileconfig` прямо в браузере и отдаёт на установку | ✅ работает |
| `web/NortInstallDNS.mobileconfig` — готовый DNS-профиль проекта (DoH NextDNS, ID `26d83c`); пользователю не нужна регистрация или ручная настройка | ✅ работает |
| `ios-app` — тёмная фирменная тема, анимированный онбординг, карточки статуса и кольцевой прогресс загрузки | ✅ UI готов; сборка проверяется в Xcode на Mac |
| Разбор IPA (Info.plist из `Payload/*.app`) на Rust, через FFI `ni_ipa_info` | ✅ работает, покрыт тестами |
| Скачивание IPA с прогрессом (`IPADownloader`) | ✅ работает |
| Deep links `nortinstall://install / pairingFile / certificate` | ✅ парсятся, UI реагирует |
| Импорт файла сопряжения через file picker | ✅ работает |
| Экран «Сертификаты»: импорт `.p12` вручную или по deep link | ✅ работает (хранение — заглушка в UserDefaults, Keychain в roadmap) |
| Экран «Справка»: установка DNS-профиля и «доверять» сертификату — те же шаги, что на сайте | ✅ работает |
| Аутентификация Apple ID (anisette) | 🚧 заглушка |
| Запрос provisioning-профиля | 🚧 заглушка |
| Переподписание бинарника (ldid) | 🚧 заглушка |
| Установка на устройство | 🚧 заглушка |

## Структура

```
NortInstall/
├── .github/workflows/
│   ├── checks.yml         Тесты Rust + проверка JS/plist на каждый push/PR
│   ├── release.yml        По тегу v*: сборка IPA → подпись всеми сертификатами → Releases
│   └── pages.yml          Деплой web/ на GitHub Pages
├── web/                     Лендинг + вся «обвязка» установки
│   ├── config.js            Репозиторий и полный список сертификатов (правится вручную)
│   ├── index.html           Установка, DNS, сертификаты (legacy), туториалы
│   ├── install.html         Мастер «Начать установку»: LocalDevVPN → DNS → сертификат → доверие
│   ├── certificates.html    Полный список сертификатов с фильтрами и статусами
│   ├── dns.html             Генератор DNS-профиля из ID NextDNS (+ полный туториал)
│   ├── open.html            Ссылки open.html?url=https://…/app.ipa
│   ├── animations.css/js    Scroll-reveal, hover-эффекты, парение иконки (на всех страницах)
│   ├── NortInstallDNS.mobileconfig  Готовый профиль проекта (NextDNS ID: 26d83c)
│   ├── app-icon.svg / app-icon.png  Иконка (вектор + растр 1024px)
│   └── favicon-192.png         Фавиконка для всех страниц
├── rust-core/           Ядро на Rust: разбор IPA, FFI (ni_ipa_info / ni_free_string)
│   └── include/         Заголовок и modulemap для Swift
├── ios-app/NortInstall/ SwiftUI-приложение
│   ├── NortInstallApp.swift   Точка входа, онбординг, deep links, тёмная тема
│   ├── Theme.swift            Цвета, градиенты, кнопки, карточки и внешние ссылки
│   ├── AppState.swift         Deep links, сертификат, статус сопряжения
│   ├── Assets.xcassets/       Иконка приложения 1024×1024 без альфа-канала
│   ├── Views/                 Onboarding / Root / Install / AppleID / PairingFile /
│   │                          Certificates / Help
│   ├── Engine/                URLScheme, IPADownloader, InstallEngine, RustFFI,
│   │                          AnisetteClient, AppleAuthService
│   └── Models/AppError.swift
├── scripts/
│   ├── build-rust.sh      rust-core → build/NortInstallFFI.xcframework
│   ├── build-ipa.sh       Неподписанный build/NortInstall.ipa (XcodeGen + xcodebuild)
│   └── sign-ipa.sh        Подпись .ipa из p12+mobileprovision (CI и локально)
└── project.yml           Описание Xcode-проекта (XcodeGen)
```

## Интерфейс приложения

- Пять экранов первого запуска: приветствие → LocalDevVPN → готовый DNS-профиль →
  сертификат и доверие → запуск. Переходы вперёд и назад анимированы в нужную сторону.
- Главный экран с зелёным градиентом `#26d83c`, каскадным появлением карточек и
  живыми индикаторами сертификата/сопряжения.
- Установка IPA: поле ссылки, анимированное кольцо загрузки с процентами и карточка
  метаданных, полученных из Rust-core.
- Тёмная тема и зелёный tint действуют на всех экранах независимо от системной темы.
- Ссылки GitHub Pages в `Theme.swift` (`Links.dnsProfile` и `Links.certificates`)
  и `NORT_REPO` в `web/config.js` настроены на `syxmwii/NortInstall`; при форке
  замените владельца в этих трёх местах.

## Сборка IPA через GitHub Actions

Пайплайн повторяет схему SideInstaller (основной репозиторий → неподписанный
IPA → подпись сертификатами → сайт берёт готовые файлы):

1. **`release.yml`, джоб `build`** (macos-15): Rust core → xcframework →
   XcodeGen → `xcodebuild` без подписи → `build/NortInstall.ipa` как artifact.
2. **Джоб `sign`** — матрица сертификатов A…L. Для каждого ID из секретов
   репозитория берутся:
   - `CERT_<ID>_P12_B64` — сертификат `.p12` в base64
   - `CERT_<ID>_PASSWORD` — пароль от `.p12`
   - `CERT_<ID>_PROFILE_B64` — `.mobileprovision` в base64

   Если секретов нет — сертификат просто пропускается (с warning).
   `sign-ipa.sh` распаковывает IPA, кладёт профиль, подписывает codesign'ом
   во временном keychain и собирает `NortInstall-<ID>.ipa`.
3. **Джоб `publish`** — прикрепляет все IPA к релизу тега.
4. **Сайт** ссылается на них напрямую: в `web/config.js` один раз задаёте
   `NORT_REPO = "user/repo"` — все кнопки на index и certificates.html ведут
   на `releases/latest/download/NortInstall[-ID].ipa`.

Запуск: `git tag v0.1.0 && git push --tags`. Прогон вручную — Actions → release
→ Run workflow (релиз не публикуется, только артефакты).

**Сайт на GitHub Pages:** Settings → Pages → Source: GitHub Actions — дальше
`pages.yml` сам деплоит `web/` при каждом пушe в main.

**Секреты и подпись:** `.p12` и пароли живут только в Secrets репозитория.
Важно: распространять чужие enterprise-сертификаты — юридически серая зона,
используйте свои или имеющие легальное распространение.

## Сертификаты и DNS (как у SideInstaller)

Схема та же, что у оригинала, но DNS максимально упрощён для пользователя:

1. **Кому DNS нужен, а кому нет.** Установка своим Apple ID (основной путь на
   iOS 27+ и «своя подпись») — **без DNS-профиля вообще**. DNS нужен только для
   enterprise-сборок: Apple отзывает такие сертификаты по запросам к
   `ocsp.apple.com`, `ocsp2.apple.com` и `ppq.apple.com`, а профиль направляет
   DNS через DoH-резолвер с этими доменами в denylist.
2. **Пользователю — ноль настройки.** `web/NortInstallDNS.mobileconfig` — это
   уже настроенный профиль проекта (NextDNS ID `26d83c`): скачал → Настройки →
   «Профиль загружен» → Установить. Никаких аккаунтов NextDNS.
   Смена ID — одна строка `ServerURL` в этом файле.
   **Мастер установки** (`web/install.html`) ведёт по шагам: LocalDevVPN →
   DNS-профиль → выбор сертификата → «Доверять» → готово. Прогресс и выбранный
   сертификат сохраняются в localStorage.
3. **Продвинутый вариант** — `web/dns.html`: генератор профиля из собственного
   конфига NextDNS (как раньше). Полезно, если хочется свой резолвер.
4. **Сертификаты на сайте** (`#legacy`) подписывают именно **NortInstall**:
   карточки «NortInstall · сертификат A/B» + инструкция «Как разрешить
   приложение» (Настройки → Основные → VPN и управление устройствами →
   Доверять). Кнопки-заглушки заменятся на реальные .ipa после первых
   подписанных сборок.

Приложение повторяет то же самое: экран **Справка** показывает те же шаги,
экран **Сертификаты** принимает `.p12` по `nortinstall://certificate` или
импортом из «Файлов».

## Проверить без Mac

Rust-ядро и веб-страницы работают на любой системе:

```bash
# тесты ядра (создаёт фейковый IPA и разбирает его)
cargo test --manifest-path rust-core/Cargo.toml

# веб-страница: просто откройте web/index.html в браузере
# проверка deep link: web/open.html?url=https://server/app.ipa
```

## Сборка на Mac

1. Установите [XcodeGen](https://github.com/yonaskolb/XcodeGen) и rustup с целью iOS:
   `rustup target add aarch64-apple-ios`
2. Соберите ядро: `./scripts/build-rust.sh` → появится `build/NortInstallFFI.xcframework`
3. Сгенерируйте проект: `xcodegen`
4. Откройте `NortInstall.xcodeproj` и запустите на подключённом iPhone.
   XCFramework по умолчанию собирается только для `aarch64-apple-ios`; для
   симулятора добавьте `aarch64-apple-ios-sim` и/или `x86_64-apple-ios` в
   `scripts/build-rust.sh`. Для настоящей установки в любом случае нужно устройство.

Схема `nortinstall://` зарегистрирована в `project.yml`, deep links работают сразу.

## Roadmap

Порядок шагов «от простого к сложному», с подсказками, где смотреть:

1. **Разбор и валидация IPA** — ✅ сделано: Info.plist (имя, bundle id, версия,
   min iOS) + `embedded.mobileprovision` (наличие профиля и Team ID — XML
   достаётся из CMS-обёртки). Покрыто тестами.
2. **Anisette + вход в Apple ID.** `AnisetteClient` уже делает реальный запрос
   к anisette-v3-совместимому серверу и декодирует заголовки (✅). Осталось:
   SRP-6a handshake с `gsa.apple.com/grandslam/GsService2` (init → complete,
   2FA). Свой сервер: [SideStore/anisette-v3-server](https://github.com/SideStore/anisette-v3-server),
   протокол GSA — в исходниках SideStore/AltStore.
3. **Профиль и регистрация приложения** у Apple ID (7-дневные free-сертификаты,
   10 app ID на free-аккаунт — нужна переиспользуемая схема, как в SideStore).
4. **Переподписание** — встроить `ldid`, обновить `Info.plist`, entitlements
   (`get-task-allow`, aps-environment).
5. **Установка на устройство.** Самый сложный шаг: SideStore использует
   entitlement-демон и ABI-трюки, недоступные из App Store. Реальный путь —
   собирать приложение как sideloaded (не из App Store) и повторять подход
   SideStore: [SideStore/SideStore](https://github.com/SideStore/SideStore),
   [SideStore/ipa-http-server], [pymobiledevice3] для понимания lockdown.
6. **Сопряжение на устройстве** (iOS 27+, как у siboot) — отдельное направление,
   требует собственного исследования.

## Безопасность

- Пароль Apple ID используется только локально и не отправляется никуда, кроме
  серверов Apple (когда auth будет реализована).
- Никакой аналитики, серверов и аккаунтов.
- Если будете распространять сборки: **предупреждайте пользователей о форках**.
  Открытый код позволяет кому угодно собрать клон с интерфейсом 1-в-1 и
  воровать Apple ID. Публикуйте контрольные суммы и держите единственный
  официальный источник.

## Лицензия

MIT — делайте что хотите, но сохраните упоминание авторов и не выдавайте
сборки за официальные чужих проектов.
