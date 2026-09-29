# Setup

## 1. Copy files into your existing project

Copy everything in this zip's `lib/` folder and `pubspec.yaml` over your
project's own `lib/` and `pubspec.yaml`. This replaces every file from
before (home screen, player, etc.) with the new versions.

The `android/build.gradle.kts` in this zip is the same Gradle 36 fix from
earlier -- copy it over too if you don't already have it applied.

## 2. Add two permission lines to your AndroidManifest.xml

I don't have your actual `android/app/src/main/AndroidManifest.xml` (it's 
not something I generated), so add these two lines yourself, inside
`<manifest>` and above `<application>`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

The first covers Android 12 and below; the second covers Android 13+. The
app requests this permission itself on first launch (via `permission_handler`)
-- these manifest lines just declare that the app is allowed to ask.

## 3. Install and run

```
rm pubspec.lock
flutter clean
flutter pub get
flutter run
```

## How automatic scanning works, and its limits

On first launch, the app asks for audio/storage permission, then looks
directly inside these folders for playable files:

- `/storage/emulated/0/Music`
- `/storage/emulated/0/Download`
- `/storage/emulated/0/Downloads`
- `/storage/emulated/0/Recordings`

This uses direct file-path access rather than Android's MediaStore API.
It's simpler and works on most real devices once permission is granted,
but isn't guaranteed on every device, Android version, or emulator image.
If the scan finds nothing, the app shows an explanation and the "Add
songs" option in the top-right menu still lets you pick files by hand --
same file picker as before.

Pull down on the Library tab any time to rescan.

## Known unknown: album art field name

`audio_metadata_reader`'s docs confirm the fields used for title, artist,
album, duration and the `pictures` list, but not the exact field on a
`Picture` object that holds the raw image bytes. Rather than guess and
risk another compile error, `library_service.dart` tries several likely
field names at runtime and simply falls back to a placeholder icon if
none match. If you'd like real album art and it's not showing up, tell me
and I can look up the exact field name.
