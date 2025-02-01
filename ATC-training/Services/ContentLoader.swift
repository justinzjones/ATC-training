import Foundation

actor ContentLoader {
    static let shared = ContentLoader()
    
    func loadContent() async throws -> [AppContent] {
        guard let url = Bundle.main.url(forResource: "ATC_content_v1", withExtension: "json") else {
            throw ContentError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let content = try decoder.decode(ContentWrapper.self, from: data)
        return content.appContent
    }
    
    func loadSubsections() async throws -> [Subsection] {
        guard let url = Bundle.main.url(forResource: "ATC_content_v1", withExtension: "json") else {
            throw ContentError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let content = try decoder.decode(SubsectionsWrapper.self, from: data)
        return content.subsections
    }
    
    func loadLessons() async throws -> [Lesson] {
        guard let url = Bundle.main.url(forResource: "ATC_content_v1", withExtension: "json") else {
            throw ContentError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let content = try decoder.decode(LessonsWrapper.self, from: data)
        return content.lessons
    }
}

struct ContentWrapper: Codable {
    let appContent: [AppContent]
    
    enum CodingKeys: String, CodingKey {
        case appContent = "App Content"
    }
}

struct SubsectionsWrapper: Codable {
    let subsections: [Subsection]
    
    enum CodingKeys: String, CodingKey {
        case subsections = "Subsections"
    }
}

struct LessonsWrapper: Codable {
    let lessons: [Lesson]
    
    enum CodingKeys: String, CodingKey {
        case lessons = "Lessons"
    }
}

enum ContentError: Error {
    case fileNotFound
} 