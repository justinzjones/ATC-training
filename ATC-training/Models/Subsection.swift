import Foundation

struct Subsection: Identifiable, Codable {
    let id: String
    let section: String
    let title: String?
    let description: String
    
    // Add memberwise initializer for previews
    init(id: String, section: String, title: String?, description: String) {
        self.id = id
        self.section = section
        self.title = title
        self.description = description
    }
    
    enum CodingKeys: String, CodingKey {
        case section = "Section"
        case title = "Subsection"
        case description = "Description/Objective"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        section = try container.decode(String.self, forKey: .section)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        id = "\(section)-\(title ?? "intro")"
    }
} 