import SwiftUI

struct OnboardingView: View {
    @State private var page = 0
    @State private var mist = false
    @State private var floatFood = false
    var complete: () -> Void
    var skip: () -> Void

    var body: some View {
        ZStack {
            JotTheme.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 32)
                ZStack {
                    onboardingContent
                        .id(page)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    if mist {
                        Color.white.opacity(0.78)
                            .blur(radius: 18)
                            .transition(.opacity)
                    }
                }
                .frame(height: 610)
                Spacer()
                pageDots
                if page == 2 {
                    agreementLine
                        .padding(.top, 34)
                        .transition(.opacity)
                }
                primaryButton
                    .padding(.top, page == 2 ? 26 : 44)
                    .padding(.bottom, 64)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                floatFood = true
            }
        }
        .onChange(of: page) { _ in
            floatFood = false
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                floatFood = true
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {} label: {
                HStack(spacing: 8) {
                    Text("语言设定")
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black.opacity(0.18))
                }
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(JotTheme.ink)
                .padding(.horizontal, 18)
                .frame(height: 58)
                .grayControl(corner: 18)
            }
            Spacer()
            Button("跳过") { skip() }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.20))
        }
        .padding(.horizontal, 32)
        .padding(.top, 26)
        .slowAppear(delay: 0.02, distance: 10, blur: 2)
    }

    @ViewBuilder
    private var onboardingContent: some View {
        if page == 0 {
            VStack(spacing: 54) {
                ZStack {
                    cornerGuides
                        .slowAppear(delay: 0.03, distance: 12, blur: 3)
                    Image("OnboardingFood")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 480)
                        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
                        .offset(y: floatFood ? -10 : 5)
                        .rotationEffect(.degrees(floatFood ? 0.8 : -0.5))
                        .slowAppear(delay: 0.10, distance: 26, blur: 7)
                }
                Text("一拍，即贴")
                    .font(.system(size: 43, weight: .heavy, design: .rounded))
                    .foregroundStyle(JotTheme.ink)
            }
        } else if page == 1 {
            VStack(spacing: 36) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(.white.opacity(0.52))
                        .frame(width: 470, height: 330)
                        .rotationEffect(.degrees(-2))
                        .slowAppear(delay: 0.02, distance: 24, blur: 6)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(Color(red: 0.98, green: 0.91, blue: 0.68).opacity(0.42))
                                .frame(height: 92)
                                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                                .rotationEffect(.degrees(-2))
                        }
                    Image("OnboardingFood")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 245)
                        .offset(x: 8, y: 8)
                        .scaleEffect(floatFood ? 1.018 : 0.99)
                        .slowAppear(delay: 0.12, distance: 30, blur: 7)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("生煎包")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                        Text("138 kcal")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.22))
                    }
                    .foregroundStyle(.black.opacity(0.42))
                    .offset(x: 246, y: 76)
                    .slowAppear(delay: 0.22, distance: 18, blur: 3)
                }
                VStack(spacing: 16) {
                    Text("note AI")
                        .font(.system(size: 39, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black.opacity(0.36))
                    Text("发现每一口的惊喜")
                        .font(.system(size: 39, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black.opacity(0.50))
                }
            }
        } else {
            VStack(spacing: 42) {
                LogoMark()
                    .scaleEffect(1.2)
                    .slowAppear(delay: 0.04, distance: 12, blur: 3)
                ZStack {
                    Image("OnboardingFood")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 420)
                        .opacity(0.28)
                        .offset(y: floatFood ? -8 : 5)
                        .slowAppear(delay: 0.12, distance: 26, blur: 8)
                    VStack(spacing: 18) {
                        Text("采集我的生活地图")
                            .font(.system(size: 35, weight: .heavy, design: .rounded))
                        Text("照片、语音、文字都会变成轻盈的记录卡")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.32))
                    }
                    .padding(.top, 260)
                    .slowAppear(delay: 0.25, distance: 18, blur: 3)
                }
            }
        }
    }

    private var cornerGuides: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .trim(from: 0, to: 0.22)
                    .stroke(.black.opacity(0.045), lineWidth: 6)
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(Double(i) * 90))
                    .offset(x: i == 0 || i == 3 ? -230 : 230, y: i < 2 ? -185 : 185)
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index == page ? JotTheme.ink : .black.opacity(0.08))
                    .frame(width: index == page ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.32, dampingFraction: 0.86), value: page)
            }
        }
        .slowAppear(delay: 0.20, distance: 8, blur: 2)
    }

    private var agreementLine: some View {
        HStack(spacing: 9) {
            Circle()
                .stroke(.black.opacity(0.14), lineWidth: 1.4)
                .frame(width: 20, height: 20)
            Text("我已阅读并同意")
            Text("用户协议")
                .foregroundStyle(Color(red: 0.38, green: 0.60, blue: 0.70).opacity(0.45))
            Text("和")
            Text("隐私政策")
                .foregroundStyle(Color(red: 0.38, green: 0.60, blue: 0.70).opacity(0.45))
        }
        .font(.system(size: 16, weight: .bold, design: .rounded))
        .foregroundStyle(.black.opacity(0.16))
        .slowAppear(delay: 0.08, distance: 12, blur: 2)
    }

    private var primaryButton: some View {
        Button {
            if page < 2 {
                withAnimation(.easeInOut(duration: 0.18)) { mist = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                        page += 1
                        mist = false
                    }
                }
            } else {
                complete()
            }
        } label: {
            HStack(spacing: 16) {
                Text(page < 2 ? "下一步" : "开始记录")
                if page < 2 { Image(systemName: "arrow.right") }
            }
            .font(.system(size: 21, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: page < 2 ? JotLayout.onboardingCTAWidth : 420, height: JotLayout.blackCTAHeight)
            .background(page < 2 ? JotTheme.ink : Color.black.opacity(0.56), in: Capsule())
        }
        .pressDepth()
        .slowAppear(delay: 0.24, distance: 14, blur: 2)
    }
}
