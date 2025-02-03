import Foundation

struct Airport: Codable {
    let icao: String
    let iata: String
    let name: String
    let shortName: String
    let elevation: Int
    let isControlled: Bool
    let groundFrequencies: GroundFrequencies
    let runways: [Runway]
    let taxiways: [Taxiway]
    let fbos: [FBO]
    let commonLocations: [String]?
    let commonRoutes: [CommonRoute]?
    
    enum CodingKeys: String, CodingKey {
        case icao = "ICAO"
        case iata = "IATA"
        case name = "Name"
        case shortName = "ShortName"
        case elevation = "Elevation"
        case isControlled = "IsControlled"
        case groundFrequencies = "Ground_Frequencies"
        case runways = "Runways"
        case taxiways = "Taxiways"
        case fbos = "FBOs"
        case commonLocations = "CommonLocations"
        case commonRoutes = "CommonRoutes"
    }
}

struct GroundFrequencies: Codable {
    let ground: [String]
    let tower: [String]
    let clearance: String
    
    enum CodingKeys: String, CodingKey {
        case ground = "Ground"
        case tower = "Tower"
        case clearance = "Clearance"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle ground frequencies that could be string or array
        if let singleGround = try? container.decode(String.self, forKey: .ground) {
            ground = [singleGround]
        } else {
            ground = try container.decode([String].self, forKey: .ground)
        }
        
        // Handle tower frequencies that could be string or array
        if let singleTower = try? container.decode(String.self, forKey: .tower) {
            tower = [singleTower]
        } else {
            tower = try container.decode([String].self, forKey: .tower)
        }
        
        // Clearance is always a single frequency
        clearance = try container.decode(String.self, forKey: .clearance)
    }
}

struct Runway: Codable {
    let identifier: String
    let length: Int
    let width: Int
    let surface: String
    
    enum CodingKeys: String, CodingKey {
        case identifier = "Identifier"
        case length = "Length"
        case width = "Width"
        case surface = "Surface"
    }
}

struct Taxiway: Codable {
    let identifier: String
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case identifier = "Identifier"
        case description = "Description"
    }
}

struct FBO: Codable {
    let name: String
    let location: String
    let accessVia: [String]
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case location = "Location"
        case accessVia = "AccessVia"
    }
}

struct CommonRoute: Codable {
    let from: String
    let to: String
    let instructions: String
    let hotspots: [String]
    
    enum CodingKeys: String, CodingKey {
        case from = "From"
        case to = "To"
        case instructions = "Instructions"
        case hotspots = "Hotspots"
    }
}

struct AirportsWrapper: Codable {
    let airports: [Airport]
    
    enum CodingKeys: String, CodingKey {
        case airports = "Airports"
    }
} 