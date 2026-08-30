# ბტკ საველე აპლიკაცია · BTK Field App

[![Launch BTK Web](https://img.shields.io/badge/Launch-BTK%20Web-2D8653?logo=googlechrome&logoColor=white)](https://btc.qgis.ge)
[![GCA GitHub](https://img.shields.io/badge/Georgian%20Cartographers%20Association-GitHub-181717?logo=github&logoColor=white)](https://github.com/Georgian-Cartographers-Association)
[![Build & Release](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/actions/workflows/release.yml/badge.svg)](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/actions/workflows/release.yml)
[![Version](https://img.shields.io/github/v/release/Georgian-Cartographers-Association/GCA-btc-field-app?label=version)](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/Georgian-Cartographers-Association/GCA-btc-field-app/total?label=downloads&color=blue)](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/releases)
[![Android](https://img.shields.io/badge/Android-APK%20%7C%20AAB-3DDC84?logo=android&logoColor=white)](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/releases/latest)
[![Windows](https://img.shields.io/badge/Windows-Setup%20%7C%20Portable-0078D4?logo=windows&logoColor=white)](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/releases/latest)
[![Linux AppImage](https://img.shields.io/badge/Linux-AppImage-FCC624?logo=linux&logoColor=black)](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/releases/latest)
[![Debian/Ubuntu](https://img.shields.io/badge/.deb-Debian%20%7C%20Ubuntu-A81D33?logo=debian&logoColor=white)](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/releases/latest)
[![Fedora/RHEL](https://img.shields.io/badge/.rpm-Fedora%20%7C%20RHEL-EE0000?logo=redhat&logoColor=white)](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.7-027DFD?logo=flutter&logoColor=white)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-22863A)](LICENSE)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/Georgian-Cartographers-Association/GCA-btc-field-app)

თბილისის სახელმწიფო უნივერსიტეტისა და **[საქართველოს კარტოგრაფთა ასოციაციის](https://github.com/Georgian-Cartographers-Association)** ერთობლივი პროექტი — **ბუნებრივ-ტერიტორიული კომპლექსების (ბტკ) ველური კვლევის ღია კოდის პლატფორმა.** მუშაობს ვებ-ბრაუზერში, Android ტელეფონზე, Windows-სა და Linux-ზე — მონაცემები ადგილობრივ მოწყობილობაზე რჩება.

A joint project of Tbilisi State University and the **Georgian Cartographers Association** — a free, open-source field survey platform for **landscape natural-territorial complexes (NTC/BTC)**. Runs on the web, Android, Windows, and Linux, with your data staying local.

- **[Launch BTK Web](https://btc.qgis.ge)** — სრული აპლიკაცია ბრაუზერში, ინსტალაცია არ სჭირდება
- **[Download the app](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/releases/latest)** — Android APK, Windows Setup/Portable, Linux AppImage/.deb/.rpm
- **[ბტკ ბლანკი](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/releases/latest)** — 6-სექციანი ფიზიკურ-გეოგრაფიული ბლანკი GPS-ით, ფოტოებით, ტრეკით
- **[Import / Export](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/releases/latest)** — .btk, .btkz (ფოტო+GPS), PDF, KML, GeoJSON, CSV, GPX
- **[სტატისტიკა](https://btc.qgis.ge)** — dashboard: ჩანაწერების ანალიზი, bar charts, mini-map
- **[GPS ტრეკი](https://btc.qgis.ge)** — ჩაწერა → GPX ექსპორტი → .btkz-ში ავტოჩართვა

## Screenshots

> 📸 **სქრინშოტები მალე გამოჩნდება.** გამოაქვეყნეთ პრობლემა ან pull request `docs/screenshots/` დირექტორიაში.

<!-- გთხოვთ, ჩაანაცვლოთ ქვემოთ მოცემული placeholder-ები რეალური სქრინშოტებით:

<table>
  <tr>
    <td width="33%"><a href="docs/screenshots/records.png"><img src="docs/screenshots/records.png" alt="ჩანაწერების სია"></a></td>
    <td width="33%"><a href="docs/screenshots/form.png"><img src="docs/screenshots/form.png" alt="ბტკ ბლანკი"></a></td>
    <td width="33%"><a href="docs/screenshots/map.png"><img src="docs/screenshots/map.png" alt="რუქა"></a></td>
  </tr>
  <tr>
    <td align="center"><b>ჩანაწერები</b></td>
    <td align="center"><b>ბტკ ბლანკი</b></td>
    <td align="center"><b>რუქა</b></td>
  </tr>
  <tr>
    <td width="33%"><a href="docs/screenshots/stats.png"><img src="docs/screenshots/stats.png" alt="სტატისტიკა"></a></td>
    <td width="33%"><a href="docs/screenshots/gps.png"><img src="docs/screenshots/gps.png" alt="GPS ტრეკი"></a></td>
    <td width="33%"><a href="docs/screenshots/export.png"><img src="docs/screenshots/export.png" alt="ექსპორტი"></a></td>
  </tr>
  <tr>
    <td align="center"><b>სტატისტიკა</b></td>
    <td align="center"><b>GPS ტრეკი</b></td>
    <td align="center"><b>ექსპორტი</b></td>
  </tr>
</table>
-->

## რა არის ბტკ?

> **ბტკ = ბუნებრივ-ტერიტორიული კომპლექსი**
> ლანდშაფტური გეოგრაფიის ფუნდამენტური სტრუქტურული ერთეული — ტერიტორიის ის ნაწილი, სადაც **რელიეფი, ნიადაგი, მცენარეულობა, ჰიდროლოგია და მიკროკლიმატი** ერთიან, ურთიერთდაკავშირებულ სისტემას ქმნიან.

ეს აპლიკაცია გამიზნულია **პირდაპირ ველში** ბტკ-ების კომპონენტების აღწერისა და გაზომვებისთვის, ნ. ბერუჩაშვილის **ლანდშაფტურ-გეოფიზიკური კვლევის** მეთოდიკის მიხედვით.

## ჩამოტვირთვა

| პლატფორმა | ფაილი | შენიშვნა |
|---|---|---|
| **Android** | `btk-android-arm64.apk` | თანამედროვე ტელეფონები (რეკომენდ.) |
| **Android** | `btk-android-arm32.apk` | ძველი ტელეფონები |
| **Android** | `btk-android-x86_64.apk` | ემულატორები |
| **Android** | `app-release.aab` | Google Play Store |
| **Windows** | `btk-windows-setup-X.Y.Z.exe` | ინსტალერი (Start Menu) |
| **Windows** | `btk-windows.zip` | Portable — unzip და გაუშვი |
| **Linux** | `btk-linux-X.Y.Z.AppImage` | ნებისმიერი distro — `chmod +x` |
| **Linux** | `btk-linux-X.Y.Z.deb` | Debian / Ubuntu / Mint |
| **Linux** | `btk-linux-X.Y.Z.rpm` | Fedora / RHEL / openSUSE |
| **Web** | — | **[btc.qgis.ge](https://btc.qgis.ge)** |

SHA256 checksums: `checksums-android.txt` · `checksums-windows.txt` · `checksums-linux.txt`

<details>
<summary>ინსტალაციის ინსტრუქციები</summary>

**Android** — `Settings → Install unknown apps → ჩართეთ → APK გაუშვეთ`

**Linux (AppImage)**
```bash
chmod +x btk-linux-*.AppImage && ./btk-linux-*.AppImage
```

**Linux (Debian/Ubuntu)**
```bash
sudo dpkg -i btk-linux-*.deb && sudo apt-get install -f
```

</details>

## ფუნქციები

### ბტკ ბლანკი — 6 სექცია

| # | სექცია | ველები |
|---|---|---|
| 1 | **ძირითადი** | ID, სახელი, თარიღი, GPS კოორდინატები, ლოკაცია |
| 2 | **ფიზ.-გეოგ.** | გეოლ. ფორმაცია, რელიეფი, მორფ. დახასიათება, მიგრ. რეჟიმი, ტენიანობა |
| 3 | **მცენარეულობა** | ვ.სტრუქტ. ტიპი/ინდ., იარუსები, სახეობები, სიმ./სიმძლ./ფენოფაზა |
| 4 | **ნიადაგი** | ტიპი, ჰორიზონტები, გეოჰ. ინდ., ზ.ფენ. ფორმ. + ფოტოები |
| 5 | **გეომასა** | სექციები — პედო / ლითო / ჰიდრო / ფიტომასა |
| 6 | **ვ.სტრუქტურა** | ტიპი, ინდ., სიმ., აღწ. + ფოტოები |

### ექსპორტი და იმპორტი

| ფორმატი | შიგთავსი | |
|---|---|---|
| **.btk** | JSON — ჩანაწერების სრული მონაცემები | import ✓ · export ✓ |
| **.btkz** | ZIP — ჩანაწერები + ფოტოები + GPS ტრეკები | import ✓ · export ✓ |
| **PDF** | A4, ქართული ფონტი (Noto Sans Georgian), ფოტოები | export · share |
| **KML** | Google Earth / QGIS / ArcGIS | export · share |
| **GeoJSON** | QGIS / Mapbox / Leaflet | export · share |
| **CSV** | Excel / Sheets — 5 კოორდინატთა ფორმატი | export · share |
| **GPX** | GPS ტრეკი — Garmin / OsmAnd / Strava | export · share |

ყველა ფორმატი **Android, Windows და Linux**-ზე სრულად მუშაობს.

### რუქა და GPS

- **OpenStreetMap** + **OpenTopoMap** tile overlay-ები
- ლოკალური **რასტრული რუქები** — Bounding Box + გამჭვირვალობა (ნიადაგი, ლანდშაფტი, რელიეფი)
- საქართველოს ადმინ. საზღვრები (GeoJSON) — რეგიონები, მუნიციპალიტეტები
- **GPS ტრეკის ჩაწერა** — ფონური, ტრეკის ისტორია, GPX ექსპორტი
- ტრეკი **ავტომატურად .btkz-ში** — ჩანაწერების მიმდებარე დღის ტრეკები

### UX

| ფუნქცია | |
|---|---|
| Long-press → multi-select | batch export / batch PDF / batch წაშლა |
| Record duplication | "(ასლი)" სუფიქსით |
| Discard dialog | unsaved changes გაფრთხილება |
| Auto-update banner | GitHub Releases-ს ამოწმებს, ახალი ვერსია → notification |
| სტატისტიკა / Dashboard | bar chart, სიხშირე, mini-map |
| ღია / მუქი ფონი | Material 3 theming |
| ქართული / English | სრული ბილინგვალური UI |

### შენახვის რეჟიმები

| რეჟიმი | |
|---|---|
| **Local** | SQLite — მოწყობილობაზე, ინტერნეტი არ სჭირდება |
| **Cloud** | Firebase Firestore — real-time sync |
| **Expedition** | გუნდური — საექსპედიციო ID-ით |

## Development

```bash
git clone https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app.git
cd GCA-btc-field-app
flutter pub get
flutter gen-l10n
flutter run                                        # OS auto-detect
flutter run -d windows                             # Windows desktop
flutter build apk --split-per-abi --release        # Android APKs (arm64, arm32, x86_64)
flutter build appbundle --release                  # AAB (Google Play)
flutter build windows --release                    # Windows
flutter build linux --release                      # Linux
flutter build web --release                        # Web
```

## CI/CD

| Job | Trigger | Artifacts |
|---|---|---|
| `build-apk` | `git tag v*` | arm64 / arm32 / x86_64 APK + AAB + SHA256 |
| `build-windows` | `git tag v*` | Setup .exe + Portable .zip + SHA256 |
| `build-linux` | `git tag v*` | AppImage + .deb + .rpm + SHA256 |

```bash
git tag v1.20.0 && git push origin v1.20.0
```

## არქიტექტურა

```
lib/
├── main.dart · router.dart          # Entry point, GoRouter
├── models/                          # BtkRecord, GpsTrack, Photo, …
├── database/btk_database.dart       # SQLite (sqflite_common_ffi)
├── data/
│   ├── repositories/                # Local / Cloud / Expedition
│   └── services/
│       ├── export_service.dart      # .btk .btkz PDF KML GeoJSON CSV GPX
│       └── update_service.dart      # GitHub Releases auto-update check
└── features/
    ├── map/                         # FlutterMap + tile layers + raster
    ├── form/                        # 6-section BTC form + photo panels
    ├── records/                     # List, search, batch ops, import/export
    ├── stats/                       # Dashboard — charts + mini-map
    ├── gps/                         # Track recording + history
    ├── auth/                        # Firebase Auth
    ├── expedition/                  # Expedition mode
    ├── settings/                    # Storage mode, theme, locale, coord fmt
    ├── layers/                      # Raster layer manager
    └── pdf/                         # Methodology PDF viewer (164 გვ.)
```

## Tech Stack

| Package | |
|---|---|
| `flutter_map` | OSM / OpenTopoMap tiles + raster overlay |
| `flutter_riverpod` | State management |
| `sqflite` + `sqflite_common_ffi` | SQLite (Android + Desktop) |
| `firebase_core` + `firebase_auth` + `cloud_firestore` | Cloud sync |
| `geolocator` | GPS + track recording |
| `file_picker` | File import / Save As dialog |
| `pdf` + `printing` | PDF export (Noto Sans Georgian) |
| `archive` | .btkz ZIP encoding/decoding |
| `share_plus` | Share files (mobile, desktop, web) |
| `http` | GitHub Releases API + weather |
| `package_info_plus` | Version for update check |
| `url_launcher` | Open release page |
| `go_router` | Navigation |
| `flex_color_scheme` | Material 3 theming |

## ციტირება · Citation

თუ ამ პროგრამას კვლევაში იყენებთ, გთხოვთ, მიუთითოთ:

If you use this software in your research, please cite it:

```bibtex
@software{btk_field_app,
  author       = {Georgian Cartographers Association},
  title        = {BTK Field App — ბტკ საველე აპლიკაცია},
  year         = {2024--2026},
  publisher    = {GitHub},
  institution  = {Tbilisi State University, Georgian Cartographers Association},
  url          = {https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app}
}
```

> Georgian Cartographers Association. (2024–2026). *BTK Field App — ბტკ საველე აპლიკაცია* [Computer software]. Tbilisi State University. https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app

## მადლობა · Acknowledgements

ეს პროგრამა აგებულია ღია კოდის გეოსივრცული და Flutter-ის საზოგადოებებზე, მათ შორის: MapLibre / flutter_map, Firebase, sqflite, Riverpod, GoRouter, Noto Sans Georgian, და სხვა. სრული სია `pubspec.yaml`-ში.

## ლიტერატურა

- ბერუჩაშვილი ნ. *საველე ლანდშაფტურ-გეოფიზიკური კვლევა და ლანდშაფტური კარტოგრაფირება.* თბ., 2024
- ბერუჩაშვილი ნ. *ბუნებრივ-ტერიტორიული კომპლექსების ლანდშაფტურ-გეოფიზიკური კვლევისა და მდგომარეობათა კარტოგრაფირების მეთოდიკა.* თბ., 1983
- გორდეზიანი თ. *ლანდშაფტური კარტოგრაფიის თეორიული საფუძვლები.* თბ., 2014

## License

[MIT](LICENSE)

---

<div align="center">

[Georgian Cartographers Association](https://github.com/Georgian-Cartographers-Association) · [Tbilisi State University](https://tsu.ge) · 2024–2026

</div>
