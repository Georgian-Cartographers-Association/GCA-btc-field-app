# ბტკ საველე აპლიკაცია · BTK Field App

<div align="center">

**ივანე ჯავახიშვილის სახ. თბილისის სახელმწიფო უნივერსიტეტი**  
**ალ. ასლანიკაშვილის სახ. საქართველოს კარტოგრაფთა ასოციაცია**

[![Build & Release](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/actions/workflows/release.yml/badge.svg)](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/actions/workflows/release.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.7-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.20.0-brightgreen)](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/releases/latest)

🌐 **[btc.qgis.ge](https://btc.qgis.ge)** &nbsp;·&nbsp; 📥 [ბოლო Release](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/releases/latest)

</div>

---

## რა არის ბტკ?

> **ბტკ = ბუნებრივ-ტერიტორიული კომპლექსი**  
> ლანდშაფტური გეოგრაფიის ფუნდამენტური სტრუქტურული ერთეული — ტერიტორიის ის ნაწილი, სადაც **რელიეფი, ნიადაგი, მცენარეულობა, ჰიდროლოგია და მიკროკლიმატი** ერთიან, ურთიერთდაკავშირებულ სისტემას ქმნიან.

ეს აპლიკაცია გამიზნულია **პირდაპირ ველში** ბტკ-ების კომპონენტების აღწერისა და გაზომვებისთვის.

---

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

SHA256 checksums: `checksums-android.txt`, `checksums-windows.txt`, `checksums-linux.txt`

### Android ინსტალაცია

```
Settings → Install unknown apps → ჩართეთ → APK გაუშვეთ
```

### Linux (AppImage)

```bash
chmod +x btk-linux-*.AppImage && ./btk-linux-*.AppImage
```

### Linux (Debian/Ubuntu)

```bash
sudo dpkg -i btk-linux-*.deb && sudo apt-get install -f
```

---

## ფუნქციები

### ბტკ ბლანკი (6 სექცია)

| # | სექცია | შიგთავსი |
|---|---|---|
| 1 | **ძირითადი** | ID, სახელი, თარიღი, GPS კოორდინატები, ლოკაცია |
| 2 | **ფიზ.-გეოგ.** | გეოლ. ფორმაცია, რელიეფი, მორფ. დახასიათება, მიგრ. რეჟიმი, ტენიანობა |
| 3 | **მცენარეულობა** | ვ.სტრუქტ. ტიპი/ინდ., იარუსები, სახეობები, სიმ./სიმძლ./ფენოფაზა |
| 4 | **ნიადაგი** | ტიპი, ჰორიზონტები, გეოჰ. ინდ., ზ.ფენ. ფორმ. + ფოტოები |
| 5 | **გეომასა** | სექციები — პედო/ლითო/ჰიდრო/ფიტომასა |
| 6 | **ვ.სტრუქტურა** | ტიპი, ინდ., სიმ., აღწ. + ფოტოები |

### 🗺️ რუქა

- **OpenStreetMap** + **OpenTopoMap** — tile overlay-ები
- ლოკალური **რასტრული რუქები** (ნიადაგი, ლანდშაფტი, რელიეფი) — Bounding Box + გამჭვირვალობა
- საქართველოს ადმინ. საზღვრები (GeoJSON)
- მეზობელი ქვეყნების შრეები
- ზომის გამზომი ინსტრუმენტი

### 📡 GPS ტრეკი

- ტრეკის ჩაწერა ველში (ფონური)
- ჩაწერილი ტრეკების ისტორია
- GPX ექსპორტი
- **ტრეკი ავტომატურად .btkz-ში შედის** — ჩანაწერების მიმდებარე დღის ტრეკები

### 📤 ექსპორტი & იმპორტი

| ფორმატი | | |
|---|---|---|
| **.btk** | JSON — ჩანაწერების სრული მონაცემები | import ✓ / export ✓ |
| **.btkz** | ZIP — ჩანაწერები + ფოტოები + GPS ტრეკები | import ✓ / export ✓ |
| **PDF** | A4, ქართული ფონტი, ფოტოები | export / share |
| **KML** | Google Earth / QGIS | export / share |
| **GeoJSON** | QGIS / MapBox | export / share |
| **CSV** | Excel / Google Sheets (5 კოორდ. ფორმატი) | export / share |
| **GPX** | GPS ტრეკი | export / share |

**ყველა ფორმატი მუშაობს Android, Windows და Linux-ზე.**

### 📊 სტატისტიკა

- ჩანაწერების სულ / GPS / GPS-გარეშე
- ბოლო 6 თვის bar chart
- გეოლ. ფორმ. / რელიეფ. ტიპ. / ნიადაგ. სიხშირე
- Mini-map — ყველა ჩანაწერი FlutterMap-ზე

### 📱 UX

- **Long-press → multi-select** — batch export / PDF / წაშლა
- **Record duplication** — "(ასლი)" სუფიქსით
- **Discard dialog** — unsaved changes გაფრთხილება
- **Auto-update banner** — GitHub Releases-ს ამოწმებს, ახალი ვერსია → notification
- ღია / მუქი ფონი · ქართული / English

### ☁️ შენახვის რეჟიმები

| რეჟიმი | |
|---|---|
| **Local** | SQLite — მოწყობილობაზე |
| **Cloud** | Firebase Firestore — real-time sync |
| **Expedition** | გუნდური — საექსპედიციო ID-ით |

---

## Development

```bash
git clone https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app.git
cd GCA-btc-field-app
flutter pub get
flutter gen-l10n
flutter run                           # OS auto-detect
flutter run -d windows                # Windows desktop
flutter build apk --split-per-abi --release   # Android APKs
flutter build appbundle --release             # AAB (Play Store)
flutter build windows --release               # Windows
flutter build linux --release                 # Linux
flutter build web --release                   # Web
```

---

## CI/CD

| Job | Trigger | Artifacts |
|---|---|---|
| `build-apk` | `git tag v*` | arm64 / arm32 / x86_64 APK + AAB + SHA256 |
| `build-windows` | `git tag v*` | Setup .exe + Portable .zip + SHA256 |
| `build-linux` | `git tag v*` | AppImage + .deb + .rpm + SHA256 |

```bash
# Release
git tag v1.20.0 && git push origin v1.20.0
```

---

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

---

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

---

## ლიტერატურა

- ბერუჩაშვილი ნ. *საველე ლანდშაფტურ-გეოფიზიკური კვლევა და ლანდშაფტური კარტოგრაფირება.* თბ., 2024
- ბერუჩაშვილი ნ. *ბუნებრივ-ტერიტორიული კომპლექსების ლანდშაფტურ-გეოფიზიკური კვლევისა და მდგომარეობათა კარტოგრაფირების მეთოდიკა.* თბ., 1983
- გორდეზიანი თ. *ლანდშაფტური კარტოგრაფიის თეორიული საფუძვლები.* თბ., 2014

---

<div align="center">

[Georgian Cartographers Association](https://github.com/Georgian-Cartographers-Association) · 2024–2026

</div>
