import SwiftUI

struct WeekHomeView: View {
    let notes: [MemoryNote]
    @Binding var selectedNote: MemoryNote?
    @Binding var showingCapture: Bool
    @Binding var showingSettings: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    weekStrip
                    VStack(alignment: .leading, spacing: 18) {
                        FlipStringText(
                            text: "6.13",
                            font: .system(size: 32, weight: .regular, design: .rounded),
                            color: Color(red: 0.36, green: 0.22, blue: 0.22),
                            stagger: 0.045
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(notes) { note in
                            Button { selectedNote = note } label: { NoteRow(note: note) }
                                .buttonStyle(.plain)
                                .slowAppear(delay: 0.12, distance: 18, blur: 3)
                        }
                    }
                    .padding(26)
                    .background {
                        RoundedRectangle(cornerRadius: JotLayout.homeCardCorner, style: .continuous)
                            .fill(.white.opacity(0.45))
                            .overlay {
                                PaperLines()
                                    .opacity(0.30)
                                    .clipShape(RoundedRectangle(cornerRadius: JotLayout.homeCardCorner, style: .continuous))
                            }
                            .overlay(RoundedRectangle(cornerRadius: JotLayout.homeCardCorner, style: .continuous).stroke(JotTheme.hairline))
                    }
                    Spacer(minLength: 180)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar.padding(.horizontal, 34).padding(.bottom, 10) }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                LogoMark()
                Spacer()
                Button { showingSettings = true } label: {
                    Image(systemName: "hexagon")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(JotTheme.ink)
                        .frame(width: 48, height: 48)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)
            FlipStringText(
                text: "2026",
                font: .system(size: 31, weight: .heavy, design: .rounded),
                color: .black.opacity(0.11),
                stagger: 0.035
            )
            FlipStringText(
                text: "06.08 - 06.14",
                font: .system(size: 31, weight: .heavy, design: .rounded),
                color: JotTheme.ink,
                stagger: 0.026
            )
        }
    }

    private var weekStrip: some View {
        HStack(spacing: 8) {
            ForEach(weekDays) { item in
                VStack(spacing: 8) {
                    Text(item.weekday).font(.system(size: 14, weight: .bold, design: .rounded))
                    FlipStringText(
                        text: "\(item.day)",
                        font: .system(size: 20, weight: .heavy, design: .rounded),
                        color: .black.opacity(item.isSelected ? 0.82 : 0.32),
                        spacing: -1,
                        stagger: 0.035
                    )
                        .frame(width: item.isSelected ? 72 : 52, height: item.isSelected ? 72 : 52)
                        .background(item.isSelected ? Color.white.opacity(0.86) : Color.black.opacity(0.045), in: RoundedRectangle(cornerRadius: item.isSelected ? 27 : 26, style: .continuous))
                }
                .foregroundStyle(.black.opacity(item.isSelected ? 0.82 : 0.32))
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var weekDays: [WeekDayItem] {
        [
            WeekDayItem(weekday: "一", day: 8),
            WeekDayItem(weekday: "二", day: 9),
            WeekDayItem(weekday: "三", day: 10),
            WeekDayItem(weekday: "四", day: 11),
            WeekDayItem(weekday: "五", day: 12),
            WeekDayItem(weekday: "六", day: 13),
            WeekDayItem(weekday: "日", day: 14)
        ]
    }

    private var bottomBar: some View {
        HStack {
            Image(systemName: "chart.pie.fill").font(.system(size: 29)).foregroundStyle(.black.opacity(0.24)).frame(width: 64, height: 64)
            Spacer()
            Button { showingCapture = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: JotLayout.bottomAddWidth, height: JotLayout.bottomAddHeight)
                    .background(JotTheme.ink, in: Capsule())
                    .softShadow()
            }
            Spacer()
            Image(systemName: "calendar").font(.system(size: 30, weight: .semibold)).foregroundStyle(JotTheme.ink).frame(width: 64, height: 64)
        }
    }
}

struct WeekDayItem: Identifiable {
    let weekday: String
    let day: Int
    var id: Int { day }
    var isSelected: Bool { day == 13 }
}

struct LogoMark: View {
    var body: some View {
        HStack(spacing: -1) {
            Text("n")
            Text("o").foregroundStyle(Color(red: 1.0, green: 0.76, blue: 0.17))
            Text("te")
        }
        .font(.system(size: 40, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .shadow(color: .black, radius: 0, x: 2, y: 0)
        .shadow(color: .black, radius: 0, x: -2, y: 0)
        .shadow(color: .black, radius: 0, x: 0, y: 2)
        .shadow(color: .black, radius: 0, x: 0, y: -2)
    }
}

struct NoteRow: View {
    let note: MemoryNote
    var body: some View {
        HStack(spacing: 16) {
            StickerImage(note: note).frame(width: 76, height: 68)
            VStack(alignment: .leading, spacing: 7) {
                Text(note.title).font(.system(size: 21, weight: .bold, design: .rounded)).foregroundStyle(Color(red: 0.23, green: 0.28, blue: 0.34))
                Text(note.time.formatted(date: .omitted, time: .shortened)).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.black.opacity(0.25))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.black.opacity(0.18))
        }
    }
}
