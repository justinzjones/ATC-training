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
    
    func loadAirports() async throws -> [Airport] {
        guard let url = Bundle.main.url(forResource: "Airports", withExtension: "json") else {
            throw ContentError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(AirportsWrapper.self, from: data)
        return wrapper.airports
    }
    
    func loadCommunications() async throws -> [Communication] {
        guard let url = Bundle.main.url(forResource: "ATC_content_v1", withExtension: "json") else {
            throw ContentError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let content = try decoder.decode(CommunicationsWrapper.self, from: data)
        return content.communications
    }
    
    func loadPhoneticAlphabet() async throws -> [String] {
        guard let url = Bundle.main.url(forResource: "ATC_content_v1", withExtension: "json") else {
            throw ContentError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let content = try decoder.decode(PhraseologyWrapper.self, from: data)
        return content.phraseology.phoneticAlphabet
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

struct CommunicationsWrapper: Codable {
    let communications: [Communication]
    
    enum CodingKeys: String, CodingKey {
        case communications = "Communications"
    }
}

struct PhraseologyWrapper: Codable {
    let phraseology: Phraseology
    
    enum CodingKeys: String, CodingKey {
        case phraseology = "Phraseology"
    }
}

struct Phraseology: Codable {
    let phoneticAlphabet: [String]
    
    enum CodingKeys: String, CodingKey {
        case phoneticAlphabet = "PhoneticAlphabet"
    }
}

enum ContentError: LocalizedError {
    case fileNotFound
    case custom(String)
    case lessonNotFound
    case noAirportsAvailable
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Required content file not found"
        case .custom(let message):
            return message
        case .lessonNotFound:
            return "Lesson content not found"
        case .noAirportsAvailable:
            return "No suitable airports available"
        }
    }
} 