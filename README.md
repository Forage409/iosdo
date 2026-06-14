# NowJot

NowJot is a SwiftUI iOS quick-capture note app.

The app does not use phone login or verification-code flows. Capture is based on
the user's real camera or photo-library content, with on-device foreground
cutout processing through Vision.

## Project

- App source: `NowJot/`
- Xcode project: `NowJot.xcodeproj`
- Shared scheme: `NowJot.xcodeproj/xcshareddata/xcschemes/NowJot.xcscheme`
- Bundle id: `com.quang.nowjot`
- Deployment target: iOS 17.0, with iOS 26 Liquid Glass used only on supported systems

## Local Validation

```sh
python scripts/validate_workspace.py
```

On macOS with Xcode available:

```sh
scripts/macos_build_and_capture.sh
```

## Codemagic

`codemagic.yaml` is committed at the repository root. Start with
`ios-simulator-debug` for an unsigned simulator `.app` build. Use
`ios-release-ipa` after adding Apple signing identities in Codemagic for
`com.quang.nowjot`.
