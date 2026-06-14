import SwiftUI

struct NoteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scrollY: CGFloat = 0
    let note: MemoryNote

    private var chromeProgress: CGFloat {
        min(max((-scrollY - 58) / 120, 0), 1)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.90, green: 0.97, blue: 0.98), JotTheme.paper], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            PaperLines()
                .padding(.top, 86)
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    GeometryReader { proxy in
                        Color.clear.preference(key: DetailScrollOffsetKey.self, value: proxy.frame(in: .named("detailScroll")).minY)
                    }
                    .frame(height: 0)
                    HStack {
                        LogoMark()
                        Spacer()
                        Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 24, weight: .heavy)).frame(width: 48, height: 48) }
                        Button {} label: { Image(systemName: "ellipsis").font(.system(size: 24, weight: .heavy)).frame(width: 48, height: 48) }
                    }
                    .foregroundStyle(.black.opacity(0.55))
                    .padding(.top, 18)
                    .opacity(1 - chromeProgress)
                    .blur(radius: chromeProgress * 4)
                    .offset(y: -chromeProgress * 18)
                    HStack(spacing: 10) {
                        ForEach(8...14, id: \.self) { day in
                            FlipStringText(
                                text: "\(day)",
                                font: .system(size: 17, weight: .heavy, design: .rounded),
                                color: .black.opacity(day == 13 ? 0.72 : 0.20),
                                spacing: -1,
                                stagger: 0.035
                            )
                                .frame(width: day == 13 ? 58 : 42, height: day == 13 ? 58 : 42)
                                .background(day == 13 ? Color.white.opacity(0.80) : Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: day == 13 ? 22 : 21, style: .continuous))
                        }
                    }
                    .slowAppear(delay: 0.08, distance: 14, blur: 3)
                    ZStack {
                        BreathingDottedFrame().frame(height: 330).offset(y: 44)
                        StickerImage(note: note).frame(width: 330, height: 260)
                    }
                    .frame(height: 410)
                    .slowAppear(delay: 0.16, distance: 22, blur: 5)
                    Text(note.title).font(.system(size: 35, weight: .heavy, design: .rounded)).foregroundStyle(Color(red: 0.23, green: 0.28, blue: 0.34))
                        .slowAppear(delay: 0.24, distance: 14, blur: 3)
                    VStack(alignment: .leading, spacing: 18) {
                        Text("tips").font(.system(size: 26, weight: .heavy, design: .rounded))
                        Divider().opacity(0.35)
                        Text(note.body).font(.system(size: 21, weight: .semibold, design: .rounded)).lineSpacing(12).foregroundStyle(JotTheme.mutedInk)
                        Label(note.prompt, systemImage: "info.circle.fill")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.22))
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: JotLayout.tipsCardCorner, style: .continuous)
                            .fill(.white.opacity(0.64))
                            .overlay(RoundedRectangle(cornerRadius: JotLayout.tipsCardCorner, style: .continuous).stroke(Color(red: 0.80, green: 0.86, blue: 0.86).opacity(0.52), lineWidth: 1.5))
                    )
                    .slowAppear(delay: 0.30, distance: 20, blur: 4)
                    FlipStringText(
                        text: "2026.06.13 7:32",
                        font: .system(size: 22, weight: .heavy, design: .rounded),
                        color: .black.opacity(0.12),
                        stagger: 0.02
                    )
                    .slowAppear(delay: 0.36, distance: 10, blur: 2)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 90)
            }
            .coordinateSpace(name: "detailScroll")
            .onPreferenceChange(DetailScrollOffsetKey.self) { scrollY = $0 }

            VStack(spacing: 0) {
                compactChrome
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .opacity(chromeProgress)
                    .offset(y: chromeProgress == 0 ? -18 : 0)
                    .blur(radius: (1 - chromeProgress) * 5)
                Spacer()
            }
        }
    }

    private var compactChrome: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(JotTheme.ink)
                    .frame(width: 54, height: 54)
                    .glassCircle()
            }
            Spacer()
            Button {} label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(JotTheme.ink)
                    .frame(width: 54, height: 54)
                    .glassCircle()
            }
        }
        .padding(.vertical, 6)
    }
}

private struct DetailScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
