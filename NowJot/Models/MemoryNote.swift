import Foundation
import SwiftUI
import UIKit

struct MemoryNote: Identifiable {
    var id = UUID()
    var title: String
    var time: Date
    var body: String
    var prompt: String
    var imageName: String?
    var capturedImagePath: String? = nil
    var cutoutImagePath: String? = nil
    var capturedImage: UIImage? = nil
    var cutoutImage: UIImage? = nil
    var tint: Color
    var mode: CaptureMode

    static let sample = MemoryNote(
        title: "笔记本电脑",
        time: Calendar.current.date(bySettingHour: 7, minute: 32, second: 0, of: .now) ?? .now,
        body: "哇，这台电脑的屏幕色彩看起来很不错，是在研究什么好吃的 App 吗？虽然它不能填饱肚子，但能帮你发现更多灵感。",
        prompt: "AI tips 基于画面、文字和上下文生成。",
        imageName: nil,
        tint: Color(red: 0.90, green: 0.97, blue: 0.98),
        mode: .photo
    )
}

enum MemoryStore {
    private struct StoredNote: Codable {
        var id: UUID
        var title: String
        var time: Date
        var body: String
        var prompt: String
        var imageName: String?
        var capturedImagePath: String?
        var cutoutImagePath: String?
        var mode: CaptureMode
    }

    private static var rootDirectory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("NowJotRecords", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static var metadataURL: URL {
        rootDirectory.appendingPathComponent("records.json")
    }

    static func load() -> [MemoryNote] {
        guard let data = try? Data(contentsOf: metadataURL),
              let stored = try? JSONDecoder.noteDecoder.decode([StoredNote].self, from: data) else {
            return []
        }
        return stored.map { item in
            MemoryNote(
                id: item.id,
                title: item.title,
                time: item.time,
                body: item.body,
                prompt: item.prompt,
                imageName: item.imageName,
                capturedImagePath: item.capturedImagePath,
                cutoutImagePath: item.cutoutImagePath,
                capturedImage: image(named: item.capturedImagePath),
                cutoutImage: image(named: item.cutoutImagePath),
                tint: Color(red: 0.90, green: 0.97, blue: 0.98),
                mode: item.mode
            )
        }
    }

    static func save(_ notes: [MemoryNote]) {
        let stored = notes.map { note in
            var capturedPath = note.capturedImagePath
            var cutoutPath = note.cutoutImagePath
            if let capturedImage = note.capturedImage {
                capturedPath = write(image: capturedImage, named: "\(note.id.uuidString)-original.jpg", asPNG: false)
            }
            if let cutoutImage = note.cutoutImage {
                cutoutPath = write(image: cutoutImage, named: "\(note.id.uuidString)-cutout.png", asPNG: true)
            }
            return StoredNote(
                id: note.id,
                title: note.title,
                time: note.time,
                body: note.body,
                prompt: note.prompt,
                imageName: note.imageName,
                capturedImagePath: capturedPath,
                cutoutImagePath: cutoutPath,
                mode: note.mode
            )
        }
        if let data = try? JSONEncoder.noteEncoder.encode(stored) {
            try? data.write(to: metadataURL, options: [.atomic])
        }
    }

    private static func write(image: UIImage, named filename: String, asPNG: Bool) -> String? {
        let url = rootDirectory.appendingPathComponent(filename)
        let data = asPNG ? image.pngData() : image.jpegData(compressionQuality: 0.88)
        guard let data else { return nil }
        do {
            try data.write(to: url, options: [.atomic])
            return filename
        } catch {
            return nil
        }
    }

    private static func image(named filename: String?) -> UIImage? {
        guard let filename else { return nil }
        let url = rootDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

private extension JSONEncoder {
    static var noteEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var noteDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

enum CaptureMode: String, CaseIterable, Identifiable, Hashable, Codable {
    case photo, voice, text
    var id: String { rawValue }
    var title: String { self == .photo ? "一拍" : self == .voice ? "一句" : "一写" }
    var symbol: String { self == .photo ? "camera.viewfinder" : self == .voice ? "waveform" : "pencil.line" }
    var placeholder: String { self == .photo ? "对准要记录的东西" : self == .voice ? "说出这个瞬间" : "写下刚刚想到的" }
}
