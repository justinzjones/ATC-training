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
}

struct ContentWrapper: Codable {
    let appContent: [AppContent]
    
    enum CodingKeys: String, CodingKey {
        case appContent = "App Content"
    }
}

enum ContentError: Error {
    case fileNotFound
} 