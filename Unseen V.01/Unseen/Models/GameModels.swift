import Foundation
import SceneKit

// MARK: - Asset Catalogs

struct AssetCatalog {
    
    static let commercialBuildings = [
        "building-a", "building-b", "building-c", "building-d", "building-e",
        "building-f", "building-g", "building-h", "building-i", "building-j",
        "building-k", "building-l", "building-m", "building-n"
    ]
    
    static let commercialSkyscrapers = [
        "building-skyscraper-a", "building-skyscraper-b", "building-skyscraper-c",
        "building-skyscraper-d", "building-skyscraper-e"
    ]
    
    static let commercialLowDetail = [
        "low-detail-building-a", "low-detail-building-b", "low-detail-building-c",
        "low-detail-building-d", "low-detail-building-e", "low-detail-building-f",
        "low-detail-building-g", "low-detail-building-h", "low-detail-building-i",
        "low-detail-building-j", "low-detail-building-k", "low-detail-building-l",
        "low-detail-building-m", "low-detail-building-n", "low-detail-building-wide-a",
        "low-detail-building-wide-b"
    ]
    
    static let commercialDetails = [
        "detail-awning-wide", "detail-awning", "detail-overhang-wide",
        "detail-overhang", "detail-parasol-a", "detail-parasol-b"
    ]
    
    static let industrialBuildings = [
        "building-a", "building-b", "building-c", "building-d", "building-e",
        "building-f", "building-g", "building-h", "building-i", "building-j",
        "building-k", "building-l", "building-m", "building-n", "building-o",
        "building-p", "building-q", "building-r", "building-s", "building-t"
    ]
    
    static let industrialDetails = [
        "chimney-basic", "chimney-large", "chimney-medium", "chimney-small",
        "detail-tank"
    ]
    
    static let suburbanBuildings = [
        "building-type-a", "building-type-b", "building-type-c", "building-type-d",
        "building-type-e", "building-type-f", "building-type-g", "building-type-h",
        "building-type-i", "building-type-j", "building-type-k", "building-type-l",
        "building-type-m", "building-type-n", "building-type-o", "building-type-p",
        "building-type-q", "building-type-r", "building-type-s", "building-type-t",
        "building-type-u"
    ]
    
    static let suburbanDetails = [
        "driveway-long", "driveway-short", "fence-1x2", "fence-1x3", "fence-1x4",
        "fence-2x2", "fence-2x3", "fence-3x2", "fence-3x3", "fence-low", "fence",
        "path-long", "path-short", "path-stones-long", "path-stones-messy",
        "path-stones-short", "planter", "tree-large", "tree-small"
    ]
    
    static let roadsStraight = ["road-straight", "road-straight-half"]
    static let roadsCurves = ["road-bend", "road-bend-sidewalk", "road-curve", "road-curve-pavement"]
    static let roadsIntersections = ["road-intersection", "road-crossroad", "road-crossing"]
    static let roadsEnds = ["road-end", "road-end-round"]
    static let roadsSpecial = ["road-roundabout", "road-bridge", "road-split"]
    
    static let roadsLights = [
        "light-curved", "light-curved-double", "light-curved-cross",
        "light-square", "light-square-double", "light-square-cross"
    ]
    
    static let roadsConstruction = [
        "construction-barrier", "construction-cone", "construction-light"
    ]
    
    static let urbanTrees = [
        "tree-large", "tree-small", "tree-park-large", "tree-park-pine-large",
        "tree-pine-large", "tree-pine-small", "tree-shrub"
    ]
    
    static let urbanDetails = [
        "detail-barrier-type-a", "detail-barrier-type-b", "detail-barrier-strong-type-a",
        "detail-bench", "detail-block", "detail-dumpster-closed", "detail-dumpster-open",
        "detail-light-double", "detail-light-single", "detail-light-traffic"
    ]
    
    static let urbanVehicles = [
        "truck-flat", "truck-green-cargo", "truck-green", "truck-grey-cargo", "truck-grey"
    ]
    
    static let urbanGrass = [
        "grass", "grass-corner", "grass-corner-inner", "grass-hill"
    ]
}

// MARK: - City Scenarios

enum CityScenario: String, CaseIterable, Identifiable {
    case stillwater = "Stillwater"
    case crossway = "Crossway"
    case hightown = "Hightown"
    case lowfield = "Lowfield"
    case ironreach = "Ironreach"
    case clearview = "Clearview"
    case edgeport = "Edgeport"
    case stonegate = "Stonegate"
    case sunfall = "Sunfall"
    case nullCity = "Null City"
    case unknown = "Unknown City"
    
    var id: String { rawValue }
    
    var openingLine: String {
        switch self {
        case .stillwater: return "Nothing seems to happen here."
        case .crossway: return "Everyone passes through."
        case .hightown: return "Eyes are already watching."
        case .lowfield: return "Crowds gather easily."
        case .ironreach: return "Work never really stops."
        case .clearview: return "People trust what they see."
        case .edgeport: return "Everything comes and goes."
        case .stonegate: return "Neighborhoods keep to themselves."
        case .sunfall: return "Nothing is urgent… until it is."
        case .nullCity: return "Patterns don't hold here."
        case .unknown: return ""
        }
    }
    
    var scenarioConfig: ScenarioConfig {
        switch self {
        case .stillwater:
            return ScenarioConfig(
                initialActivity: 0.2, baseResistance: 0.8, spreadRate: 0.3,
                responseSpeed: 0.4, connectivity: 0.5, volatility: 0.2
            )
        case .crossway:
            return ScenarioConfig(
                initialActivity: 0.7, baseResistance: 0.4, spreadRate: 0.6,
                responseSpeed: 0.5, connectivity: 0.9, volatility: 0.5
            )
        case .hightown:
            return ScenarioConfig(
                initialActivity: 0.5, baseResistance: 0.6, spreadRate: 0.4,
                responseSpeed: 0.9, connectivity: 0.6, volatility: 0.3
            )
        case .lowfield:
            return ScenarioConfig(
                initialActivity: 0.9, baseResistance: 0.3, spreadRate: 0.8,
                responseSpeed: 0.6, connectivity: 0.7, volatility: 0.6
            )
        case .ironreach:
            return ScenarioConfig(
                initialActivity: 0.6, baseResistance: 0.5, spreadRate: 0.5,
                responseSpeed: 0.5, connectivity: 0.6, volatility: 0.3,
                cycleDependent: true
            )
        case .clearview:
            return ScenarioConfig(
                initialActivity: 0.7, baseResistance: 0.3, spreadRate: 0.5,
                responseSpeed: 0.7, connectivity: 0.6, volatility: 0.9
            )
        case .edgeport:
            return ScenarioConfig(
                initialActivity: 0.8, baseResistance: 0.4, spreadRate: 0.7,
                responseSpeed: 0.5, connectivity: 0.8, volatility: 0.5,
                retention: 0.3
            )
        case .stonegate:
            return ScenarioConfig(
                initialActivity: 0.5, baseResistance: 0.5, spreadRate: 0.6,
                responseSpeed: 0.5, connectivity: 0.2, volatility: 0.3
            )
        case .sunfall:
            return ScenarioConfig(
                initialActivity: 0.7, baseResistance: 0.2, spreadRate: 0.6,
                responseSpeed: 0.2, connectivity: 0.6, volatility: 0.4,
                lateResponseMultiplier: 3.0
            )
        case .nullCity:
            return ScenarioConfig(
                initialActivity: Float.random(in: 0.3...0.8),
                baseResistance: Float.random(in: 0.2...0.8),
                spreadRate: Float.random(in: 0.3...0.8),
                responseSpeed: Float.random(in: 0.2...0.9),
                connectivity: Float.random(in: 0.2...0.9),
                volatility: Float.random(in: 0.4...0.9)
            )
        case .unknown:
            return ScenarioConfig(
                initialActivity: Float.random(in: 0.2...0.9),
                baseResistance: Float.random(in: 0.1...0.9),
                spreadRate: Float.random(in: 0.2...0.9),
                responseSpeed: Float.random(in: 0.3...1.0),
                connectivity: Float.random(in: 0.1...1.0),
                volatility: Float.random(in: 0.3...1.0)
            )
        }
    }
    
    var layoutStyle: CityLayoutStyle {
        switch self {
        case .stillwater: return .sparse
        case .crossway: return .hub
        case .hightown: return .grid
        case .lowfield: return .dense
        case .ironreach: return .industrial
        case .clearview: return .mixed
        case .edgeport: return .coastal
        case .stonegate: return .blocks
        case .sunfall: return .sprawl
        case .nullCity: return .chaotic
        case .unknown: return CityLayoutStyle.allCases.randomElement() ?? .grid
        }
    }
}

struct ScenarioConfig {
    let initialActivity: Float
    let baseResistance: Float
    let spreadRate: Float
    let responseSpeed: Float
    let connectivity: Float
    let volatility: Float
    var cycleDependent: Bool = false
    var retention: Float = 0.7
    var lateResponseMultiplier: Float = 1.0
}

enum CityLayoutStyle: CaseIterable {
    case sparse, hub, grid, dense, industrial, mixed, coastal, blocks, sprawl, chaotic
}

// MARK: - District

enum DistrictType: CaseIterable {
    case residential
    case commercial
    case industrial
    case civic
    case park
    
    var buildingModels: [String] {
        switch self {
        case .residential:
            return AssetCatalog.suburbanBuildings
        case .commercial:
            return AssetCatalog.commercialBuildings + AssetCatalog.commercialSkyscrapers
        case .industrial:
            return AssetCatalog.industrialBuildings
        case .civic:
            return AssetCatalog.commercialLowDetail
        case .park:
            return []
        }
    }
    
    var detailModels: [String] {
        switch self {
        case .residential:
            return AssetCatalog.suburbanDetails
        case .commercial:
            return AssetCatalog.commercialDetails
        case .industrial:
            return AssetCatalog.industrialDetails
        case .civic:
            return AssetCatalog.urbanDetails
        case .park:
            return AssetCatalog.urbanTrees
        }
    }
    
    var folder: String {
        switch self {
        case .residential: return "Suburban"
        case .commercial: return "Commercial"
        case .industrial: return "Industrial"
        case .civic: return "Commercial"
        case .park: return "Urban"
        }
    }
}

class District: Identifiable, ObservableObject {
    let id = UUID()
    let gridX: Int
    let gridY: Int
    let type: DistrictType
    
    @Published var density: Float
    @Published var stress: Float
    @Published var resistance: Float
    @Published var connectivity: Float
    @Published var influence: Float
    @Published var activityLevel: Float
    @Published var suppressionLevel: Float
    @Published var isSeeded: Bool = false
    
    var worldPosition: SCNVector3 {
        let tileSize: Float = 12.0
        return SCNVector3(Float(gridX) * tileSize, 0, Float(gridY) * tileSize)
    }
    
    init(gridX: Int, gridY: Int, type: DistrictType, config: ScenarioConfig) {
        self.gridX = gridX
        self.gridY = gridY
        self.type = type
        
        let initialDensity: Float
        switch type {
        case .residential: initialDensity = Float.random(in: 0.4...0.7)
        case .commercial: initialDensity = Float.random(in: 0.6...0.9)
        case .industrial: initialDensity = Float.random(in: 0.3...0.5)
        case .civic: initialDensity = Float.random(in: 0.5...0.7)
        case .park: initialDensity = Float.random(in: 0.2...0.4)
        }
        
        self.density = initialDensity
        self.stress = Float.random(in: 0.1...0.4)
        self.resistance = config.baseResistance + Float.random(in: -0.1...0.1)
        self.connectivity = config.connectivity + Float.random(in: -0.2...0.2)
        self.influence = 0.0
        self.activityLevel = config.initialActivity * initialDensity
        self.suppressionLevel = 0.0
    }
    
    var statusMessage: String {
        if influence > 0.8 {
            return ["Something has changed.", "The pattern is complete.", "It's everywhere now."].randomElement()!
        } else if influence > 0.5 {
            return ["Behavior is shifting.", "Unusual patterns emerging.", "People act differently."].randomElement()!
        } else if influence > 0.2 {
            return ["Subtle changes noticed.", "Activity fluctuating.", "Watch closely."].randomElement()!
        } else if suppressionLevel > 0.5 {
            return ["Increased presence.", "Streets feel different.", "Authority visible."].randomElement()!
        } else if activityLevel < 0.3 {
            return ["Quiet.", "Few venture out.", "Stillness."].randomElement()!
        } else {
            return ["Normal activity.", "Routine continues.", "Nothing unusual."].randomElement()!
        }
    }
    
    var activityDescription: String {
        if activityLevel > 0.8 { return "Bustling" }
        if activityLevel > 0.6 { return "Active" }
        if activityLevel > 0.4 { return "Moderate" }
        if activityLevel > 0.2 { return "Quiet" }
        return "Empty"
    }
}

// MARK: - City

class City: ObservableObject {
    let scenario: CityScenario
    let config: ScenarioConfig
    let gridSize: Int
    
    @Published var districts: [[District]]
    @Published var gameTime: Int = 0
    @Published var dayPhase: DayPhase = .day
    @Published var globalInfluence: Float = 0.0
    @Published var globalSuppression: Float = 0.0
    @Published var gameState: GameState = .playing
    @Published var score: Int = 0
    @Published var citySeed: UInt64 = 0
    
    enum DayPhase {
        case dawn, day, dusk, night
        
        var activityMultiplier: Float {
            switch self {
            case .dawn: return 0.6
            case .day: return 1.0
            case .dusk: return 0.8
            case .night: return 0.3
            }
        }
    }
    
    enum GameState {
        case playing, saturation, coexistence, collapse, eradication
    }
    
    init(scenario: CityScenario, gridSize: Int = 6) {
        self.scenario = scenario
        self.config = scenario.scenarioConfig
        self.gridSize = gridSize
        self.districts = []
        
        // Generate reproducible seed
        self.citySeed = UInt64(Date().timeIntervalSince1970 * 1000) ^ UInt64(scenario.hashValue)
        srand48(Int(citySeed))
        
        generateCity()
    }
    
    private func generateCity() {
        districts = []
        for y in 0..<gridSize {
            var row: [District] = []
            for x in 0..<gridSize {
                let type = determineDistrictType(x: x, y: y)
                row.append(District(gridX: x, gridY: y, type: type, config: config))
            }
            districts.append(row)
        }
    }
    
    private func determineDistrictType(x: Int, y: Int) -> DistrictType {
        let center = gridSize / 2
        let distFromCenter = abs(x - center) + abs(y - center)
        
        switch scenario.layoutStyle {
        case .sparse:
            if Bool.random() && Bool.random() { return .park }
            return [.residential, .residential, .commercial].randomElement()!
        case .hub:
            if distFromCenter <= 1 { return .commercial }
            if distFromCenter == 2 { return [.commercial, .residential].randomElement()! }
            return .residential
        case .grid:
            if (x + y) % 3 == 0 { return .commercial }
            if (x + y) % 5 == 0 { return .industrial }
            return .residential
        case .dense:
            if distFromCenter <= 2 { return .commercial }
            return [.residential, .commercial].randomElement()!
        case .industrial:
            if y < 2 { return .industrial }
            if y == 2 { return .commercial }
            return .residential
        case .mixed:
            return DistrictType.allCases.randomElement()!
        case .coastal:
            if x == 0 { return .park }
            if x == 1 { return [.commercial, .park].randomElement()! }
            return [.residential, .commercial, .industrial].randomElement()!
        case .blocks:
            let blockType = ((x / 2) + (y / 2)) % 3
            switch blockType {
            case 0: return .residential
            case 1: return .commercial
            default: return .industrial
            }
        case .sprawl:
            if distFromCenter <= 1 { return .commercial }
            return .residential
        case .chaotic:
            return DistrictType.allCases.randomElement()!
        }
    }
    
    func getDistrict(at x: Int, y: Int) -> District? {
        guard x >= 0 && x < gridSize && y >= 0 && y < gridSize else { return nil }
        return districts[y][x]
    }
    
    func getNeighbors(of district: District) -> [District] {
        let offsets = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        return offsets.compactMap { getDistrict(at: district.gridX + $0.0, y: district.gridY + $0.1) }
    }
    
    var allDistricts: [District] { districts.flatMap { $0 } }
}

// MARK: - Mutations

struct Mutation: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let effect: MutationEffect
    let cost: Int
    
    enum MutationEffect {
        case spreadBoost(Float)
        case resistanceReduction(Float)
        case stealthBoost(Float)
        case volatilityIncrease(Float)
        case connectivityExploit(Float)
        case stressFeeder(Float)
        case densityThriving(Float)
        case suppressionResist(Float)
    }
}

let availableMutations: [Mutation] = [
    Mutation(name: "Thrives when ignored", description: "Spreads faster in low-suppression areas", effect: .stealthBoost(0.3), cost: 1),
    Mutation(name: "Feeds on routine", description: "Stronger spread during day cycles", effect: .spreadBoost(0.2), cost: 1),
    Mutation(name: "Exploits connections", description: "Crosses district boundaries easier", effect: .connectivityExploit(0.4), cost: 2),
    Mutation(name: "Weakens defenses", description: "Reduces natural resistance over time", effect: .resistanceReduction(0.15), cost: 2),
    Mutation(name: "Unstable growth", description: "Faster but unpredictable spread", effect: .volatilityIncrease(0.5), cost: 1),
    Mutation(name: "Stress response", description: "Thrives in high-stress districts", effect: .stressFeeder(0.3), cost: 2),
    Mutation(name: "Crowd seeker", description: "Spreads faster in dense areas", effect: .densityThriving(0.25), cost: 1),
    Mutation(name: "Authority blind", description: "Partially ignores suppression", effect: .suppressionResist(0.2), cost: 3),
]

// MARK: - Events

struct GameEvent: Identifiable {
    let id = UUID()
    let message: String
    let type: EventType
    let districtId: UUID?
    
    enum EventType {
        case observation, spread, response, milestone, warning
    }
}
