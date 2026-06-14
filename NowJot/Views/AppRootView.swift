import SwiftUI

struct AppRootView: View {
    @State private var notes: [MemoryNote] = []
    @State private var selectedNote: MemoryNote?
    @State private var showingCapture = false
    @State private var showingSettings = false
    @State private var launchStage: LaunchStage = .onboarding
    @State private var captureInitialStage: CaptureStage = .opening

    init() {
        let qaState = QAStartState.fromProcessArguments()
        let loadedNotes = MemoryStore.load()
        _notes = State(initialValue: loadedNotes)
        _launchStage = State(initialValue: qaState.launchStage)
        _showingCapture = State(initialValue: qaState.showCapture)
        _showingSettings = State(initialValue: qaState.showSettings)
        _selectedNote = State(initialValue: qaState.showDetail ? (loadedNotes.first ?? .sample) : nil)
        _captureInitialStage = State(initialValue: qaState.captureStage)
    }

    var body: some View {
        ZStack {
            JotTheme.paper.ignoresSafeArea()
            switch launchStage {
            case .onboarding:
                OnboardingView(
                    complete: { launchStage = .home },
                    skip: { launchStage = .home }
                )
                .transition(.opacity)
            case .home:
                WeekHomeView(notes: notes, selectedNote: $selectedNote, showingCapture: $showingCapture, showingSettings: $showingSettings)
                    .transition(.opacity)
            }

            if showingCapture {
                CaptureView(
                    initialStage: captureInitialStage,
                    onCancel: {
                        withAnimation(.spring(response: 0.46, dampingFraction: 0.88)) {
                            showingCapture = false
                        }
                    },
                    onSave: { mode, title, capturedImage, cutoutImage in
                        notes.insert(
                            MemoryNote(
                                title: title,
                                time: .now,
                                body: "这个瞬间已经贴进今天。之后可以继续补照片、语音或一句文字。",
                                prompt: "建议：补一个地点或心情。",
                                imageName: nil,
                                capturedImage: capturedImage,
                                cutoutImage: cutoutImage,
                                tint: Color(red: 0.90, green: 0.97, blue: 0.98),
                                mode: mode
                            ),
                            at: 0
                        )
                        MemoryStore.save(notes)
                        withAnimation(.spring(response: 0.46, dampingFraction: 0.88)) {
                            showingCapture = false
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .animation(.spring(response: 0.52, dampingFraction: 0.88), value: showingCapture)
        .sheet(isPresented: $showingSettings) {
            SettingsSheetView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.clear)
        }
        .sheet(item: $selectedNote) { note in
            NoteDetailView(note: note)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }
}

enum LaunchStage {
    case onboarding
    case home
}

private struct QAStartState {
    var launchStage: LaunchStage = .onboarding
    var showCapture = false
    var showSettings = false
    var showDetail = false
    var captureStage: CaptureStage = .opening

    static func fromProcessArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> QAStartState {
        var state = QAStartState()
        if arguments.contains("--qa-home") || arguments.contains("--qa-capture") || arguments.contains("--qa-capture-extracting") || arguments.contains("--qa-capture-recognized") || arguments.contains("--qa-settings") || arguments.contains("--qa-detail") {
            state.launchStage = .home
        }
        state.showCapture = arguments.contains("--qa-capture") || arguments.contains("--qa-capture-extracting") || arguments.contains("--qa-capture-recognized")
        state.showSettings = arguments.contains("--qa-settings")
        state.showDetail = arguments.contains("--qa-detail")
        if arguments.contains("--qa-capture-extracting") {
            state.captureStage = .extracting
        }
        if arguments.contains("--qa-capture-recognized") {
            state.captureStage = .recognized
        }
        return state
    }
}
