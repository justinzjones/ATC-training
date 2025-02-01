import Foundation

struct Lesson: Identifiable, Codable {
    let id: String
    let section: String
    let subsection: String
    let lessonNumber: Int
    let title: String
    let objective: String
    let communicationType: String
    let isControlled: Bool
    
    enum CodingKeys: String, CodingKey {
        case section = "Section"
        case subsection = "Subsection"
        case lessonNumber = "Lesson#"
        case title = "Title"
        case objective = "Objective"
        case communicationType = "Communication Type"
        case isControlled = "Controlled"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        section = try container.decode(String.self, forKey: .section)
        subsection = try container.decode(String.self, forKey: .subsection)
        lessonNumber = try container.decode(Int.self, forKey: .lessonNumber)
        title = try container.decode(String.self, forKey: .title)
        objective = try container.decode(String.self, forKey: .objective)
        communicationType = try container.decode(String.self, forKey: .communicationType)
        isControlled = try container.decode(String.self, forKey: .isControlled) == "Yes"
        id = "\(section)-\(subsection)-\(lessonNumber)"
    }
} 