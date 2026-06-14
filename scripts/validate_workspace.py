from __future__ import annotations

import json
import plistlib
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    raise SystemExit(message)


def check_json() -> None:
    for path in (ROOT / "NowJot").rglob("Contents.json"):
        json.loads(path.read_text(encoding="utf-8"))


def check_plist() -> None:
    plist = plistlib.load((ROOT / "NowJot" / "Info.plist").open("rb"))
    required = [
        "CFBundleExecutable",
        "CFBundleIdentifier",
        "CFBundleInfoDictionaryVersion",
        "CFBundleName",
        "CFBundlePackageType",
        "CFBundleShortVersionString",
        "CFBundleVersion",
        "LSRequiresIPhoneOS",
        "NSCameraUsageDescription",
        "NSMicrophoneUsageDescription",
        "NSPhotoLibraryUsageDescription",
        "UILaunchScreen",
        "UISupportedInterfaceOrientations",
    ]
    missing = [key for key in required if key not in plist]
    if missing:
        fail(f"Info.plist is missing required keys: {missing}")


def check_scheme() -> None:
    scheme_path = ROOT / "NowJot.xcodeproj" / "xcshareddata" / "xcschemes" / "NowJot.xcscheme"
    scheme_tree = ET.parse(scheme_path)
    pbx = (ROOT / "NowJot.xcodeproj" / "project.pbxproj").read_text(encoding="utf-8")
    references = scheme_tree.findall(".//BuildableReference")
    target_ids = {
        reference.attrib["BlueprintIdentifier"]
        for reference in references
        if reference.attrib.get("BlueprintName") == "NowJot"
    }
    if not target_ids:
        fail("NowJot scheme does not contain a NowJot buildable reference.")
    missing = [target_id for target_id in sorted(target_ids) if target_id not in pbx]
    if missing:
        fail(f"Scheme target id is not aligned with the project target id: {missing}")


def check_swift_structure() -> None:
    for path in (ROOT / "NowJot").rglob("*.swift"):
        text = path.read_text(encoding="utf-8")
        balance = 0
        for char in text:
            if char == "{":
                balance += 1
            elif char == "}":
                balance -= 1
            if balance < 0:
                fail(f"Brace underflow in {path}")
        if balance != 0:
            fail(f"Brace imbalance in {path}: {balance}")

        for line_number, line in enumerate(text.splitlines(), start=1):
            quote_count = 0
            escaped = False
            for char in line:
                if escaped:
                    escaped = False
                    continue
                if char == "\\":
                    escaped = True
                    continue
                if char == '"':
                    quote_count += 1
            if quote_count % 2:
                fail(f"Odd number of quotes in {path}:{line_number}")

    glass_files = [
        ROOT / "NowJot" / "Design" / "JotTheme.swift",
        ROOT / "NowJot" / "Views" / "CaptureView.swift",
    ]
    for path in glass_files:
        text = path.read_text(encoding="utf-8")
        if "glassEffect" in text and "#if compiler(>=6.2)" not in text:
            fail(f"glassEffect is not compiler-guarded in {path}")


def check_project_references() -> None:
    pbx = (ROOT / "NowJot.xcodeproj" / "project.pbxproj").read_text(encoding="utf-8")
    missing = [path.name for path in (ROOT / "NowJot").rglob("*.swift") if path.name not in pbx]
    if missing:
        fail(f"Swift files missing from project.pbxproj: {missing}")
    if "Assets.xcassets" not in pbx:
        fail("Assets.xcassets is missing from project.pbxproj")
    for required in [
        "SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";",
        "SUPPORTS_MACCATALYST = NO;",
        "SWIFT_VERSION = 5.0;",
        "INFOPLIST_FILE = NowJot/Info.plist;",
    ]:
        if required not in pbx:
            fail(f"project.pbxproj is missing build setting: {required}")


def check_motion_coverage() -> None:
    required_tokens = {
        "NowJot/Design/JotTheme.swift": [
            "SlowAppearModifier",
            "PressDepthButtonStyle",
            "FlipGlyphText",
            "FlipStringText",
            "BreathingDottedFrame",
            "rotation3DEffect",
            "settings.liquidGlassOnHighSystem",
        ],
        "NowJot/Views/OnboardingView.swift": [
            "floatFood",
            "slowAppear",
            "pressDepth",
            "mist",
        ],
        "NowJot/Views/CaptureView.swift": [
            "revealChrome",
            "extractionMist",
            "BreathingDottedFrame",
            "RecognitionPill",
        ],
        "NowJot/Views/WeekHomeView.swift": [
            "FlipStringText",
            "slowAppear",
        ],
        "NowJot/Views/NoteDetailView.swift": [
            "FlipStringText",
            "BreathingDottedFrame",
            "slowAppear",
        ],
        "NowJot/Views/SettingsSheetView.swift": [
            "presented",
            "JotMotion.panelRise",
            "slowAppear",
            "SettingsToggleRow",
            "settings.autoCutout",
            "settings.keepOriginalPhoto",
            "settings.haptics",
            "settings.liquidGlassOnHighSystem",
        ],
    }
    for relative_path, tokens in required_tokens.items():
        text = (ROOT / relative_path).read_text(encoding="utf-8")
        missing = [token for token in tokens if token not in text]
        if missing:
            fail(f"{relative_path} is missing motion coverage tokens: {missing}")

    capture_text = (ROOT / "NowJot" / "Views" / "CaptureView.swift").read_text(encoding="utf-8")
    app_root = (ROOT / "NowJot" / "Views" / "AppRootView.swift").read_text(encoding="utf-8")
    for forbidden in ["AuthView(", "--qa-auth", "LaunchStage.auth", "case .auth"]:
        if forbidden in app_root:
            fail(f"AppRootView still exposes removed phone/code auth flow: {forbidden}")
    for forbidden in ["Image(\"SampleLaptop\")", "ExtractedLaptop", "StickerImage(note: .sample)"]:
        if forbidden in capture_text:
            fail(f"CaptureView contains a hardcoded capture/cutout placeholder: {forbidden}")
    for forbidden_asset in ["SampleLaptop.imageset", "ExtractedLaptop.imageset"]:
        if (ROOT / "NowJot" / "Assets.xcassets" / forbidden_asset).exists():
            fail(f"Assets contain a forbidden capture placeholder: {forbidden_asset}")
    for required in [
        "VNGenerateForegroundInstanceMaskRequest",
        "generateScaledMaskForImage",
        "UIImagePickerController",
        "PhotosPickerItem",
        "capturedImage",
        "cutoutImage",
        "settings.autoCutout",
        "settings.keepOriginalPhoto",
        "settings.haptics",
        "settings.liquidGlassOnHighSystem",
    ]:
        if required not in capture_text:
            fail(f"CaptureView is missing real image/cutout pipeline token: {required}")

    onboarding_text = (ROOT / "NowJot" / "Views" / "OnboardingView.swift").read_text(encoding="utf-8")
    if "手机号登录" in onboarding_text or "startAuth" in onboarding_text:
        fail("OnboardingView still exposes removed phone login copy or callback.")
    if "开始记录" not in onboarding_text:
        fail("OnboardingView final CTA should enter the app with 开始记录.")


def check_text_integrity() -> None:
    suspicious = ["�", "杈撳叆", "鍙戦", "閿欒", "鐢熺", "璁剧疆"]
    for path in (ROOT / "NowJot").rglob("*.swift"):
        text = path.read_text(encoding="utf-8")
        hits = [token for token in suspicious if token in text]
        if hits:
            fail(f"{path} contains likely mojibake text: {hits}")


def main() -> None:
    check_json()
    check_plist()
    check_scheme()
    check_swift_structure()
    check_project_references()
    check_motion_coverage()
    check_text_integrity()
    print("OK")


if __name__ == "__main__":
    main()
