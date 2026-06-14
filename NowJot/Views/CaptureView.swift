import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI
import UIKit
import Vision

struct CaptureView: View {
    @State private var mode: CaptureMode = .photo
    @State private var stage: CaptureStage = .opening
    @State private var pulse = false
    @State private var title = ""
    @State private var revealChrome = false
    @State private var extractionMist = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var cutoutImage: UIImage?
    @State private var processingError: String?
    @AppStorage("settings.autoCutout") private var autoCutout = true
    @AppStorage("settings.keepOriginalPhoto") private var keepOriginalPhoto = true
    @AppStorage("settings.haptics") private var haptics = true

    var onCancel: () -> Void = {}
    var onSave: (CaptureMode, String, UIImage?, UIImage?) -> Void

    init(
        initialStage: CaptureStage = .opening,
        onCancel: @escaping () -> Void = {},
        onSave: @escaping (CaptureMode, String, UIImage?, UIImage?) -> Void
    ) {
        _stage = State(initialValue: initialStage)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            JotTheme.paper.ignoresSafeArea()
            VStack(spacing: 22) {
                topBar
                preview
                titleArea
                Spacer()
                controls.padding(.horizontal, 52).padding(.bottom, 26)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(JotMotion.softReveal.delay(0.08)) { revealChrome = true }
            if stage == .opening {
                withAnimation(.spring(response: 0.78, dampingFraction: 0.86).delay(0.18)) { stage = .camera }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraImagePicker { image in
                receiveImage(image)
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedPhotoItem = nil
                        receiveImage(image)
                    }
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            CircleButton(symbol: "xmark") { onCancel() }
            Spacer()
            HStack(spacing: 8) {
                ForEach(CaptureMode.allCases) { item in
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) { mode = item }
                    } label: {
                        Image(systemName: item.symbol)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(mode == item ? Color.white : Color.black.opacity(0.45))
                            .frame(width: 44, height: 44)
                            .background(mode == item ? JotTheme.ink : .clear, in: Circle())
                    }
                    .pressDepth()
                }
            }
            .padding(7)
            .background(Color.black.opacity(0.045), in: Capsule())
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
        .opacity(revealChrome ? 1 : 0)
        .offset(y: revealChrome ? 0 : -14)
        .blur(radius: revealChrome ? 0 : 3)
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: JotLayout.cameraViewportCorner, style: .continuous)
                .fill(stage == .opening ? Color.black : Color(red: 0.84, green: 0.82, blue: 0.74))
                .overlay {
                    if stage != .opening {
                        if let capturedImage {
                            Image(uiImage: capturedImage)
                                .resizable()
                                .scaledToFill()
                                .blur(radius: stage == .recognized ? 9 : 2)
                                .opacity(stage == .recognized ? 0.20 : 0.92)
                        } else {
                            VStack(spacing: 14) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 48, weight: .semibold))
                                Text("拍下要记录的内容")
                                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                            }
                            .foregroundStyle(.white.opacity(0.70))
                            .slowAppear(delay: 0.18, distance: 12, blur: 3)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: JotLayout.cameraViewportCorner, style: .continuous))
                .offset(y: stage == .opening ? 110 : 0)
                .scaleEffect(stage == .opening ? 0.92 : 1)

            if stage == .extracting || stage == .recognized {
                BreathingDottedFrame().frame(width: 390, height: 300).offset(y: 18)
                if capturedImage != nil || cutoutImage != nil {
                    StickerImage(note: workingNote)
                        .frame(width: stage == .extracting ? 440 : 330, height: stage == .extracting ? 320 : 245)
                        .offset(y: stage == .extracting ? -8 : 0)
                        .scaleEffect(stage == .extracting ? 1.05 : 0.96)
                        .rotationEffect(.degrees(stage == .extracting ? -1.4 : 0))
                        .blur(radius: stage == .extracting ? 0.6 : 0)
                        .transition(.scale(scale: 0.72).combined(with: .opacity))
                }
            } else {
                RoundedRectangle(cornerRadius: 48, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 7, lineCap: .round, dash: JotLayout.recognitionDash))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.horizontal, 52)
                    .padding(.vertical, 86)
                    .scaleEffect(pulse ? 1.018 : 0.992)
                    .opacity(stage == .opening ? 0.3 : pulse ? 0.82 : 0.52)
            }

            if extractionMist {
                Color.white.opacity(0.52)
                    .blur(radius: 22)
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            }
        }
        .frame(height: JotLayout.cameraViewportHeight)
        .padding(.horizontal, 16)
        .clipShape(RoundedRectangle(cornerRadius: JotLayout.cameraViewportCorner, style: .continuous))
        .slowAppear(delay: 0.10, distance: 28, blur: 5)
    }

    private var titleArea: some View {
        Group {
            if stage == .extracting || stage == .recognized {
                Text(resolvedTitle)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.23, green: 0.28, blue: 0.34))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                TextField(mode.placeholder, text: $title)
                    .font(.system(size: 29, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.never)
                    .slowAppear(delay: 0.18, distance: 14, blur: 2)
            }
        }
    }

    private var controls: some View {
        HStack {
            CircleButton(symbol: "xmark") { onCancel() }
            Spacer()
            Button {
                if stage == .recognized {
                    impact(.medium)
                    onSave(mode, resolvedTitle, keepOriginalPhoto ? capturedImage : nil, cutoutImage)
                } else if stage == .extracting {
                    return
                } else if capturedImage == nil {
                    impact(.light)
                    showingCamera = true
                } else {
                    impact(.light)
                    startCutout()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [10, 9]))
                        .foregroundStyle(.black.opacity(0.18))
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(pulse ? 16 : -8))
                    Circle()
                        .fill(JotTheme.ink.opacity(0.82))
                        .frame(width: 68, height: 68)
                        .overlay {
                            if stage == .recognized {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 28, weight: .heavy))
                            } else if stage == .extracting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: capturedImage == nil ? "camera.fill" : "sparkles")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 25, weight: .heavy))
                            }
                        }
                }
            }
            .pressDepth()
            Spacer()
            CircleButton(symbol: "photo.on.rectangle.angled") {
                impact(.light)
                showingPhotoPicker = true
            }
        }
        .opacity(revealChrome ? 1 : 0)
        .offset(y: revealChrome ? 0 : 24)
        .blur(radius: revealChrome ? 0 : 4)
        .overlay(alignment: .top) {
            if stage == .extracting || stage == .recognized {
                RecognitionPill(text: stage == .extracting ? "正在抠图..." : (processingError ?? "已生成贴纸"))
                    .offset(y: -76)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
    }

    private var resolvedTitle: String {
        title.isEmpty ? "刚刚拍到的" : title
    }

    private var workingNote: MemoryNote {
        MemoryNote(
            title: resolvedTitle,
            time: .now,
            body: "",
            prompt: "",
            imageName: nil,
            capturedImage: capturedImage,
            cutoutImage: cutoutImage,
            tint: Color(red: 0.90, green: 0.97, blue: 0.98),
            mode: mode
        )
    }

    private func receiveImage(_ image: UIImage) {
        capturedImage = image.normalizedForVision()
        cutoutImage = nil
        processingError = nil
        if title.isEmpty { title = "刚刚拍到的" }
        withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
            stage = .camera
        }
        if autoCutout {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                startCutout()
            }
        }
    }

    private func startCutout() {
        guard let capturedImage else {
            showingCamera = true
            return
        }
        processingError = nil
        withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) { stage = .extracting }
        withAnimation(.easeInOut(duration: 0.18)) { extractionMist = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.easeOut(duration: 0.34)) { extractionMist = false }
        }
        Task {
            do {
                let cutout = try await SubjectCutoutProcessor.extractSubject(from: capturedImage)
                await MainActor.run {
                    cutoutImage = cutout
                    impact(.medium)
                    withAnimation(.spring(response: 0.62, dampingFraction: 0.84)) { stage = .recognized }
                }
            } catch {
                await MainActor.run {
                    processingError = "抠图失败，请换张图"
                    impact(.heavy)
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) { stage = .camera }
                }
            }
        }
    }

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard haptics else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

enum CaptureStage { case opening, camera, extracting, recognized }

struct RecognitionPill: View {
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkle").foregroundStyle(Color(red: 0.94, green: 0.66, blue: 0.12))
            Text(text).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(.black.opacity(0.28))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .luminousRecognitionMaterial()
    }
}

private struct LuminousRecognitionMaterial: ViewModifier {
    @AppStorage("settings.liquidGlassOnHighSystem") private var liquidGlassOnHighSystem = true

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *), liquidGlassOnHighSystem {
            content
                .glassEffect(.regular.tint(.white.opacity(0.36)), in: .capsule)
                .shadow(color: .white.opacity(0.86), radius: 22, x: 0, y: 0)
                .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 14)
        } else {
            content
                .background(
                    Capsule()
                        .fill(.white.opacity(0.80))
                        .shadow(color: .white.opacity(0.9), radius: 20)
                        .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 14)
                )
        }
        #else
        content
            .background(
                Capsule()
                    .fill(.white.opacity(0.80))
                    .shadow(color: .white.opacity(0.9), radius: 20)
                    .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 14)
            )
        #endif
    }
}

private extension View {
    func luminousRecognitionMaterial() -> some View {
        modifier(LuminousRecognitionMaterial())
    }
}

struct CircleButton: View {
    let symbol: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 25, weight: .heavy))
                .foregroundStyle(JotTheme.ink)
                .frame(width: 66, height: 66)
                .background(.white.opacity(0.88), in: Circle())
                .softShadow()
        }
        .pressDepth()
    }
}

private struct CameraImagePicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraImagePicker

        init(parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

private enum SubjectCutoutError: Error {
    case missingInput
    case noSubject
    case renderFailed
}

private enum SubjectCutoutProcessor {
    static func extractSubject(from image: UIImage) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            guard let input = CIImage(image: image) else { throw SubjectCutoutError.missingInput }
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(ciImage: input)
            try handler.perform([request])
            guard let observation = request.results?.first else { throw SubjectCutoutError.noSubject }

            let maskBuffer = try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: handler)
            let mask = CIImage(cvPixelBuffer: maskBuffer)
            let transparent = CIImage(color: .clear).cropped(to: input.extent)
            let filter = CIFilter.blendWithMask()
            filter.inputImage = input
            filter.backgroundImage = transparent
            filter.maskImage = mask
            guard let output = filter.outputImage else { throw SubjectCutoutError.renderFailed }

            let context = CIContext()
            guard let cgImage = context.createCGImage(output, from: input.extent) else {
                throw SubjectCutoutError.renderFailed
            }
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
        }.value
    }
}

private extension UIImage {
    func normalizedForVision() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
