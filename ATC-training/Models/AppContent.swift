struct AppContent: Codable, Identifiable {
    let type: ContentType
    let title: String
    let description: String
    let order: Int
    
    var id: String { title }
    
    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case title = "Title"
        case description = "Description/Objective"
        case order = "Order"
    }
}

enum ContentType: String, Codable {
    case appIntro = "AppIntro"
    case app = "App"
    case section = "Section"
} 