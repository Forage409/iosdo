import SwiftUI

struct StickerImage: View {
    let note: MemoryNote
    var body: some View {
        ZStack {
            if let cutoutImage = note.cutoutImage {
                Image(uiImage: cutoutImage)
                    .resizable()
                    .scaledToFit()
            } else if let capturedImage = note.capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else if let imageName = note.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(note.tint)
                    .overlay(Image(systemName: note.mode.symbol).font(.system(size: 30, weight: .bold)).foregroundStyle(.black.opacity(0.45)))
            }
        }
        .modifier(StickerBackingStyle(isCutout: note.cutoutImage != nil))
        .shadow(color: .black.opacity(0.09), radius: 12, x: 0, y: 8)
    }
}

private struct StickerBackingStyle: ViewModifier {
    let isCutout: Bool

    func body(content: Content) -> some View {
        if isCutout {
            content
                .padding(0)
        } else {
            content
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white)
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: JotLayout.stickerDotDash)).foregroundStyle(.black.opacity(0.12)))
                }
        }
    }
}

struct DottedFrame: View {
    var body: some View {
        RoundedRectangle(cornerRadius: JotLayout.recognitionFrameCorner, style: .continuous)
            .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: JotLayout.recognitionDash))
            .foregroundStyle(.black.opacity(0.12))
    }
}

struct PaperLines: View {
    var body: some View {
        VStack(spacing: 31) {
            ForEach(0..<18, id: \.self) { _ in
                Rectangle()
                    .fill(.black.opacity(0.035))
                    .frame(height: 1)
                    .overlay {
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 8]))
                            .foregroundStyle(.white.opacity(0.42))
                    }
            }
        }
        .padding(.horizontal, 22)
    }
}
