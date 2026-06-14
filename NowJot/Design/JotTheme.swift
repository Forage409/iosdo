import SwiftUI

enum JotTheme {
    static let paper = Color(red: 0.968, green: 0.966, blue: 0.948)
    static let panel = Color(red: 0.958, green: 0.958, blue: 0.948)
    static let ink = Color(red: 0.045, green: 0.045, blue: 0.045)
    static let mutedInk = Color(red: 0.45, green: 0.48, blue: 0.52)
    static let hairline = Color.black.opacity(0.07)
    static let focus = Color(red: 0.79, green: 0.59, blue: 0.13)
}

enum JotLayout {
    static let blackCTAHeight: CGFloat = 78
    static let authCTAWidth: CGFloat = 346
    static let onboardingCTAWidth: CGFloat = 240
    static let bottomAddWidth: CGFloat = 122
    static let bottomAddHeight: CGFloat = 72
    static let cameraViewportHeight: CGFloat = 558
    static let cameraViewportCorner: CGFloat = 58
    static let settingsTopCorner: CGFloat = 44
    static let tipsCardCorner: CGFloat = 30
    static let homeCardCorner: CGFloat = 32
    static let recognitionFrameCorner: CGFloat = 44
    static let stickerDotDash: [CGFloat] = [1, 6]
    static let recognitionDash: [CGFloat] = [28, 25]
}

enum JotMotion {
    static let softReveal = Animation.spring(response: 0.72, dampingFraction: 0.88)
    static let panelRise = Animation.spring(response: 0.62, dampingFraction: 0.86)
    static let digitFlip = Animation.interpolatingSpring(stiffness: 210, damping: 24)
    static let quickSettle = Animation.spring(response: 0.34, dampingFraction: 0.82)
}

struct GlassCircle: ViewModifier {
    @AppStorage("settings.liquidGlassOnHighSystem") private var liquidGlassOnHighSystem = true

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *), liquidGlassOnHighSystem {
            content.glassEffect(.regular.tint(.white.opacity(0.28)).interactive(), in: .circle)
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.58), lineWidth: 0.8))
        }
        #else
        content
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.58), lineWidth: 0.8))
        #endif
    }
}

extension View {
    func glassCircle() -> some View { modifier(GlassCircle()) }
    func softShadow() -> some View { shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10) }
    func grayControl(corner: CGFloat = 22) -> some View {
        background(Color.black.opacity(0.045), in: RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
    func slowAppear(delay: Double = 0, distance: CGFloat = 22, blur: CGFloat = 5) -> some View {
        modifier(SlowAppearModifier(delay: delay, distance: distance, blur: blur))
    }
    func softMist(_ active: Bool, opacity: Double = 0.78) -> some View {
        overlay {
            if active {
                Color.white.opacity(opacity)
                    .blur(radius: 22)
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
            }
        }
    }
    func pressDepth() -> some View {
        buttonStyle(PressDepthButtonStyle())
    }
}

struct SlowAppearModifier: ViewModifier {
    let delay: Double
    let distance: CGFloat
    let blur: CGFloat
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : distance)
            .scaleEffect(shown ? 1 : 0.985)
            .blur(radius: shown ? 0 : blur)
            .onAppear {
                shown = false
                withAnimation(JotMotion.softReveal.delay(delay)) {
                    shown = true
                }
            }
    }
}

struct PressDepthButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(JotMotion.quickSettle, value: configuration.isPressed)
    }
}

struct FlipGlyphText: View {
    let glyph: String
    let font: Font
    var delay: Double = 0
    var color: Color = JotTheme.ink

    @State private var shown = false

    var body: some View {
        Text(glyph)
            .font(font)
            .monospacedDigit()
            .foregroundStyle(color)
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 13)
            .rotation3DEffect(.degrees(shown ? 0 : -82), axis: (x: 1, y: 0, z: 0), anchor: .center, perspective: 0.56)
            .scaleEffect(shown ? 1 : 0.92)
            .blur(radius: shown ? 0 : 2.4)
            .id(glyph)
            .onAppear { reveal() }
            .onChange(of: glyph) { _ in reveal() }
    }

    private func reveal() {
        shown = false
        withAnimation(JotMotion.digitFlip.delay(delay)) {
            shown = true
        }
    }
}

struct FlipStringText: View {
    let text: String
    let font: Font
    var color: Color = JotTheme.ink
    var spacing: CGFloat = 0
    var stagger: Double = 0.035

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                FlipGlyphText(
                    glyph: String(character),
                    font: font,
                    delay: Double(index) * stagger,
                    color: color
                )
            }
        }
    }
}

struct BreathingDottedFrame: View {
    var cornerRadius: CGFloat = JotLayout.recognitionFrameCorner
    var lineWidth: CGFloat = 8
    var color: Color = .black.opacity(0.12)
    var dash: [CGFloat] = JotLayout.recognitionDash

    @State private var phase: CGFloat = 0
    @State private var breathing = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: dash, dashPhase: phase))
            .foregroundStyle(color)
            .scaleEffect(breathing ? 1.018 : 0.992)
            .opacity(breathing ? 0.72 : 0.38)
            .onAppear {
                withAnimation(.linear(duration: 1.45).repeatForever(autoreverses: false)) {
                    phase = -120
                }
                withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
                    breathing = true
                }
            }
    }
}
