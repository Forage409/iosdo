import SwiftUI

struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("settings.followSystemLanguage") private var followSystemLanguage = true
    @AppStorage("settings.autoCutout") private var autoCutout = true
    @AppStorage("settings.keepOriginalPhoto") private var keepOriginalPhoto = true
    @AppStorage("settings.haptics") private var haptics = true
    @AppStorage("settings.liquidGlassOnHighSystem") private var liquidGlassOnHighSystem = true
    @State private var presented = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 74)
                VStack(spacing: 18) {
                    header
                    SettingsGroup {
                        SettingsToggleRow(title: "自动抠图", symbol: "wand.and.stars", isOn: $autoCutout)
                        Divider().padding(.leading, 64).opacity(0.32)
                        SettingsToggleRow(title: "保存原图", symbol: "photo.stack", isOn: $keepOriginalPhoto)
                        Divider().padding(.leading, 64).opacity(0.32)
                        SettingsToggleRow(title: "触感反馈", symbol: "hand.tap", isOn: $haptics)
                    }
                    SettingsGroup {
                        SettingsToggleRow(title: "高系统玻璃效果", symbol: "sparkles", isOn: $liquidGlassOnHighSystem)
                        Divider().padding(.leading, 64).opacity(0.32)
                        SettingsToggleRow(title: "跟随系统语言", symbol: "globe", isOn: $followSystemLanguage)
                    }
                    SettingsGroup {
                        SettingsRow(title: "账号与安全", value: "本机处理", symbol: "face.smiling")
                        Divider().padding(.leading, 64).opacity(0.32)
                        SettingsRow(title: "隐私", value: "不上传原图", symbol: "lock.shield")
                    }
                    SettingsGroup {
                        SettingsRow(title: "关于 NowJot", value: nil, symbol: "info.circle")
                        Divider().padding(.leading, 64).opacity(0.32)
                        SettingsRow(title: "版本信息", value: "1.0", symbol: "sparkles")
                    }
                    Spacer()
                }
                .padding(.horizontal, 22)
                .background(UnevenRoundedRectangle(cornerRadii: .init(topLeading: JotLayout.settingsTopCorner, bottomLeading: 0, bottomTrailing: 0, topTrailing: JotLayout.settingsTopCorner), style: .continuous).fill(JotTheme.panel).ignoresSafeArea(edges: .bottom))
                .offset(y: presented ? 0 : 120)
                .opacity(presented ? 1 : 0.62)
                .blur(radius: presented ? 0 : 8)
            }
        }
        .onAppear {
            withAnimation(JotMotion.panelRise.delay(0.04)) {
                presented = true
            }
        }
    }

    private var header: some View {
        HStack {
            Text("设置")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(JotTheme.ink)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 21, weight: .heavy))
                    .foregroundStyle(JotTheme.ink)
                    .frame(width: 58, height: 58)
                    .glassCircle()
            }
            .pressDepth()
        }
        .padding(.horizontal, 30)
        .padding(.top, 30)
    }
}

struct SettingsGroup<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.white.opacity(0.42)).overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(.black.opacity(0.035))))
            .slowAppear(delay: 0.16, distance: 18, blur: 3)
    }
}

struct SettingsRow: View {
    let title: String
    let value: String?
    let symbol: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol).font(.system(size: 20, weight: .bold)).frame(width: 34)
            Text(title).font(.system(size: 19, weight: .bold, design: .rounded))
            Spacer()
            if let value {
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.35))
            }
            Image(systemName: "chevron.right").font(.system(size: 15, weight: .heavy)).foregroundStyle(.black.opacity(0.22))
        }
        .foregroundStyle(JotTheme.ink)
        .padding(.horizontal, 20)
        .frame(height: 64)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let symbol: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol).font(.system(size: 20, weight: .bold)).frame(width: 34)
            Text(title).font(.system(size: 19, weight: .bold, design: .rounded))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(JotTheme.ink)
        }
        .foregroundStyle(JotTheme.ink)
        .padding(.horizontal, 20)
        .frame(height: 64)
    }
}
