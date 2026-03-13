# K.K's App

A native macOS app for converting media files and scanning documents. Built for K.K Moggie. Zero external dependencies — everything works out of the box.

## Build & Run

```bash
swift build          # debug build
swift run KK         # run debug build
swift test           # run tests
```

## Architecture

**Conversion pipeline** — four methods dispatched by `OutputFormat.conversionMethod`:
- **sips** — image conversion (JPG, PNG, HEIC). Built into macOS.
- **afconvert** — audio conversion (AAC, M4A, WAV). Built into macOS.
- **lame** — MP3 encoding. Bundled binary at `Sources/KK/Vendor/lame`. Two-stage: afconvert to temp WAV, then lame encode.
- **AVFoundation** — video conversion (MP4, MOV). Uses `AVAssetExportSession`.

CLI tools are executed via `posix_spawn` (not `Process`) in `ConversionService.swift`.

**Scanner** — uses ImageCaptureCore framework (`ICDeviceBrowser`, `ICScannerDevice`). The scanner delegate flow is: browse → discover → open session → wait for `didSelect functionalUnit` (NOT `didOpenSession`) → configure DPI/size → scan. Output: PDF (via PDFKit), JPG, or PNG.

**File open handling** — uses `application(_:open:)` (URL-based, not the older `openFiles` String-based method). The `OpenedFile` is an `ObservableObject` with `@Published var url`, observed via `@ObservedObject` and `.onChange` in views.

**Window** — uses `Window` (not `WindowGroup`) to enforce a single window. This prevents duplicate tabs/windows when files are dropped on the dock icon.

## Key Conventions

- K.K uses **they/them** pronouns throughout the app (About window bio, etc.)
- Display name is **"K.K"** (one period, no trailing period) — this is a stylistic choice
- App window title: **"K.K's App"**
- The `[KK]` prefix is used for debug logging via `print()` and `NSLog()`

## Release & Deploy Process

### 1. Bump version in all locations

These must all match:
- `Sources/KK/App/KKApp.swift` — `AppVersion.current`
- `scripts/build-app.sh` — `VERSION=`
- `scripts/build-dmg.sh` — `VERSION=`
- `docs/index.html` — download URL filename and display version

### 2. Build the .app bundle

```bash
./scripts/build-app.sh
```

This will:
- Build release binary (`swift build -c release`)
- Assemble .app at `build/KK.app` with Info.plist, resources, bundled lame
- Generate the vanity mirror app icon via `scripts/generate-icon.swift`
- Code sign with Developer ID: `KEVIN MICHAEL CANTWELL (N6V2PD494A)`

### 3. Build and notarize the DMG

```bash
./scripts/build-dmg.sh
```

This will:
- Package `build/KK.app` into `build/KK-{VERSION}.dmg` with Applications symlink
- Submit to Apple notary service (uses keychain profile `"notary"`)
- Staple the notarization ticket to the DMG

Notary credentials are stored in the Keychain under profile `"notary"`. If they expire, re-create with:
```bash
xcrun notarytool store-credentials "notary" --apple-id kevin.cantwell@gmail.com --team-id N6V2PD494A
```

### 4. Commit, push, and create the GitHub release

```bash
git add -A && git commit -m "Bump version to X.Y.Z"
git push
gh release create vX.Y.Z build/KK-X.Y.Z.dmg --title "KK X.Y.Z" --notes "Release notes here"
```

The download page at https://kevin-cantwell.github.io/kk/ (served from `docs/index.html` via GitHub Pages) should already point to the new DMG filename after step 1.

## Project Structure

```
Sources/KK/
├── App/KKApp.swift              # Entry point, AppDelegate, About window
├── Models/
│   ├── MediaType.swift          # Audio/video/image detection by extension
│   └── OutputFormat.swift       # Output formats, conversion methods, CLI args
├── Services/
│   ├── ConversionService.swift  # Conversion orchestrator (sips/afconvert/lame/AVFoundation)
│   ├── FileIntakeService.swift  # File validation and analysis
│   └── ScannerService.swift     # ImageCaptureCore scanner integration
├── Views/
│   ├── ContentView.swift        # NavigationSplitView with sidebar
│   ├── Convert/                 # File conversion flow
│   ├── Scan/                    # Scanner flow
│   └── Components/              # Shared UI (DropZone, FileInfoCard, etc.)
├── Utilities/
│   ├── FileHelpers.swift        # File ops, reveal in Finder
│   └── PathSanitizer.swift      # Filename sanitization
├── Resources/kkmoggie.jpg       # Headshot for About window
└── Vendor/lame                  # Bundled MP3 encoder (arm64)

scripts/
├── build-app.sh                 # Build + sign .app
├── build-dmg.sh                 # Package + notarize DMG
└── generate-icon.swift          # Vanity mirror icon generator

docs/
└── index.html                   # GitHub Pages download site
```

## Notes

- The bundled `lame` binary is arm64 only. If targeting Intel Macs, an x86_64 or universal binary would be needed.
- The `Vendor/` directory is excluded from the SwiftPM target in Package.swift. The binary is copied into the .app by `build-app.sh`.
- `Bundle.main` is used for resources in the .app context, with `Bundle.module` as fallback for `swift run`.
