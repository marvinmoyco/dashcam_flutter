# DashCam App

An Android dash cam app built with Flutter, designed to run on an old smartphone mounted in a car. Records continuous loop footage so you always have the last few minutes of driving saved, without needing to manage clips manually.

> **Status: In development — targeting v0.2 (Unattended Dash Cam).** See [Progress](#progress) below.

## Features

**Working now**
- Live camera preview with adjustable resolution (240p–max, via `ResolutionPreset`)
- Loop recording: continuously records fixed-length clips (0.5–5 min, selectable) and restarts automatically
- Clips are renamed with a timestamp and camera label, then saved directly to the device's Gallery (`DashCam_Recordings` album) via the `gal` package
- Parallelized save-and-cleanup: saving a finished clip no longer blocks the start of the next one, closing the recording gap between segments
- In-app toast notifications confirming each save

**Not yet implemented**
- Foreground service to keep recording when the screen is off or the app is backgrounded — currently the camera is disposed on `AppLifecycleState.inactive`, so recording stops if the screen locks
- Auto-start on launch / on boot+charging
- Storage threshold management (max storage cap, auto-delete oldest clips when full)
- Runtime permission handling UI (currently relies on plugin defaults, no explicit request/rationale flow)
- Settings panel (drawer UI exists, no settings wired up yet)
- Incident detection (G-sensor), GPS tagging, in-app clip gallery/player

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.12.2)
- Android Studio or VS Code with the Flutter/Dart plugins
- A physical Android device for testing (camera features don't work well on emulators)

### Setup
```bash
git clone https://github.com/marvinmoyco/dashcam_flutter.git
cd dashcam_flutter
flutter pub get
flutter run
```

Connect an Android device via USB with USB debugging enabled, or use `flutter devices` to confirm it's detected before running.

### Key dependencies
| Package | Purpose |
|---|---|
| `camera` | Camera preview and video recording |
| `gal` | Saving recorded clips to the device gallery |
| `path` / `path_provider` | File path handling for renaming/moving clips |
| `intl` | Timestamp formatting for filenames |
| `toastification` | In-app save notifications |

## Project Structure
```
lib/
├── main.dart                    # App entry point, camera list initialization
├── recorder.dart                # Recorder class: loop timer, save/cleanup, file renaming
└── screen/
    └── dashcam_screen.dart      # Main UI: camera preview, controls, settings drawer
```

## Progress

This project follows a phased roadmap targeting incremental, usable milestones:

| Version | Milestone | Status |
|---|---|---|
| v0.1 | Manual camera recorder (preview, record/stop, save) | ✅ Done |
| v0.2 | Unattended dash cam (loop recording, foreground service, auto-start, storage limits) | 🔧 In progress — loop recording done, foreground service & storage limits pending |
| v0.3 | Smart dash cam (incident detection, GPS tagging) | ⏳ Not started |
| v0.4 | Shareable app (settings, onboarding, error handling) | ⏳ Not started |
| v1.0 | Release-ready (real-world tested) | ⏳ Not started |

**Known issues / active work:**
- Camera is disposed when the app becomes inactive (screen lock), which breaks the "mount and drive" use case — needs a foreground service
- Investigating a crash during longer continuous recording sessions

## Roadmap

Full phased plan (framework choice, timeline estimates, checkpoints) is tracked separately as part of project planning. Next milestone is a working Android foreground service so recording survives screen-off.

## Platform Notes

This project targets **Android only** for now. Continuous background recording is not possible on iOS due to Apple's platform restrictions on background camera access, so iOS support is a "nice to have" stretch goal, not a v1.0 target.
