import Foundation
import SceneKit

// MARK: - US States Data

struct USState: Identifiable {
    let id: String  // Abbreviation (e.g., "CA")
    let name: String
    let population: Int
    let centerX: Float  // Normalized 0-1 position
    let centerY: Float
    let neighbors: [String]  // Adjacent state abbreviations
    let type: StateType
    let politicalLeaning: Float  // -1 (liberal) to 1 (conservative), affects spread patterns
    
    enum StateType {
        case urban      // High density, fast spread, quick counter
        case suburban   // Mixed
        case rural      // Slow spread, resistant to change
        case swing      // Volatile, can flip easily
    }
}

let usStatesData: [USState] = [
    // Northeast
    USState(id: "ME", name: "Maine", population: 1362359, centerX: 0.92, centerY: 0.85, neighbors: ["NH"], type: .rural, politicalLeaning: -0.1),
    USState(id: "NH", name: "New Hampshire", population: 1377529, centerX: 0.91, centerY: 0.78, neighbors: ["ME", "VT", "MA"], type: .suburban, politicalLeaning: 0.0),
    USState(id: "VT", name: "Vermont", population: 643077, centerX: 0.88, centerY: 0.80, neighbors: ["NH", "NY", "MA"], type: .rural, politicalLeaning: -0.4),
    USState(id: "MA", name: "Massachusetts", population: 7029917, centerX: 0.93, centerY: 0.73, neighbors: ["NH", "VT", "NY", "CT", "RI"], type: .urban, politicalLeaning: -0.5),
    USState(id: "RI", name: "Rhode Island", population: 1097379, centerX: 0.95, centerY: 0.71, neighbors: ["MA", "CT"], type: .urban, politicalLeaning: -0.4),
    USState(id: "CT", name: "Connecticut", population: 3605944, centerX: 0.91, centerY: 0.69, neighbors: ["MA", "RI", "NY"], type: .suburban, politicalLeaning: -0.3),
    USState(id: "NY", name: "New York", population: 20201249, centerX: 0.85, centerY: 0.72, neighbors: ["VT", "MA", "CT", "NJ", "PA"], type: .urban, politicalLeaning: -0.4),
    USState(id: "NJ", name: "New Jersey", population: 9288994, centerX: 0.87, centerY: 0.65, neighbors: ["NY", "PA", "DE"], type: .urban, politicalLeaning: -0.3),
    USState(id: "PA", name: "Pennsylvania", population: 13002700, centerX: 0.82, centerY: 0.65, neighbors: ["NY", "NJ", "DE", "MD", "WV", "OH"], type: .swing, politicalLeaning: 0.0),
    USState(id: "DE", name: "Delaware", population: 989948, centerX: 0.86, centerY: 0.60, neighbors: ["PA", "NJ", "MD"], type: .suburban, politicalLeaning: -0.2),
    USState(id: "MD", name: "Maryland", population: 6177224, centerX: 0.83, centerY: 0.57, neighbors: ["PA", "DE", "WV", "VA", "DC"], type: .suburban, politicalLeaning: -0.4),
    USState(id: "DC", name: "Washington D.C.", population: 689545, centerX: 0.84, centerY: 0.55, neighbors: ["MD", "VA"], type: .urban, politicalLeaning: -0.8),
    
    // Southeast
    USState(id: "VA", name: "Virginia", population: 8631393, centerX: 0.80, centerY: 0.52, neighbors: ["MD", "DC", "WV", "KY", "TN", "NC"], type: .swing, politicalLeaning: -0.1),
    USState(id: "WV", name: "West Virginia", population: 1793716, centerX: 0.78, centerY: 0.55, neighbors: ["PA", "MD", "VA", "KY", "OH"], type: .rural, politicalLeaning: 0.6),
    USState(id: "NC", name: "North Carolina", population: 10439388, centerX: 0.80, centerY: 0.45, neighbors: ["VA", "TN", "GA", "SC"], type: .swing, politicalLeaning: 0.1),
    USState(id: "SC", name: "South Carolina", population: 5118425, centerX: 0.79, centerY: 0.38, neighbors: ["NC", "GA"], type: .suburban, politicalLeaning: 0.3),
    USState(id: "GA", name: "Georgia", population: 10711908, centerX: 0.76, centerY: 0.32, neighbors: ["NC", "SC", "FL", "AL", "TN"], type: .swing, politicalLeaning: 0.1),
    USState(id: "FL", name: "Florida", population: 21538187, centerX: 0.78, centerY: 0.15, neighbors: ["GA", "AL"], type: .swing, politicalLeaning: 0.1),
    
    // Midwest
    USState(id: "OH", name: "Ohio", population: 11799448, centerX: 0.73, centerY: 0.58, neighbors: ["PA", "WV", "KY", "IN", "MI"], type: .swing, politicalLeaning: 0.2),
    USState(id: "MI", name: "Michigan", population: 10077331, centerX: 0.70, centerY: 0.72, neighbors: ["OH", "IN", "WI"], type: .swing, politicalLeaning: 0.0),
    USState(id: "IN", name: "Indiana", population: 6785528, centerX: 0.68, centerY: 0.55, neighbors: ["MI", "OH", "KY", "IL"], type: .suburban, politicalLeaning: 0.3),
    USState(id: "IL", name: "Illinois", population: 12812508, centerX: 0.62, centerY: 0.55, neighbors: ["WI", "IN", "KY", "MO", "IA"], type: .urban, politicalLeaning: -0.3),
    USState(id: "WI", name: "Wisconsin", population: 5893718, centerX: 0.62, centerY: 0.70, neighbors: ["MI", "IL", "IA", "MN"], type: .swing, politicalLeaning: 0.0),
    USState(id: "MN", name: "Minnesota", population: 5706494, centerX: 0.55, centerY: 0.75, neighbors: ["WI", "IA", "SD", "ND"], type: .suburban, politicalLeaning: -0.2),
    USState(id: "IA", name: "Iowa", population: 3190369, centerX: 0.55, centerY: 0.62, neighbors: ["MN", "WI", "IL", "MO", "NE", "SD"], type: .rural, politicalLeaning: 0.2),
    USState(id: "MO", name: "Missouri", population: 6154913, centerX: 0.55, centerY: 0.50, neighbors: ["IA", "IL", "KY", "TN", "AR", "OK", "KS", "NE"], type: .suburban, politicalLeaning: 0.3),
    USState(id: "KY", name: "Kentucky", population: 4505836, centerX: 0.72, centerY: 0.48, neighbors: ["OH", "WV", "VA", "TN", "MO", "IL", "IN"], type: .rural, politicalLeaning: 0.5),
    USState(id: "TN", name: "Tennessee", population: 6910840, centerX: 0.70, centerY: 0.42, neighbors: ["KY", "VA", "NC", "GA", "AL", "MS", "AR", "MO"], type: .suburban, politicalLeaning: 0.4),
    
    // South Central
    USState(id: "AL", name: "Alabama", population: 5024279, centerX: 0.70, centerY: 0.32, neighbors: ["TN", "GA", "FL", "MS"], type: .rural, politicalLeaning: 0.5),
    USState(id: "MS", name: "Mississippi", population: 2961279, centerX: 0.64, centerY: 0.32, neighbors: ["TN", "AL", "LA", "AR"], type: .rural, politicalLeaning: 0.4),
    USState(id: "LA", name: "Louisiana", population: 4657757, centerX: 0.58, centerY: 0.25, neighbors: ["MS", "AR", "TX"], type: .suburban, politicalLeaning: 0.3),
    USState(id: "AR", name: "Arkansas", population: 3011524, centerX: 0.55, centerY: 0.38, neighbors: ["MO", "TN", "MS", "LA", "TX", "OK"], type: .rural, politicalLeaning: 0.5),
    USState(id: "OK", name: "Oklahoma", population: 3959353, centerX: 0.45, centerY: 0.38, neighbors: ["KS", "MO", "AR", "TX", "NM", "CO"], type: .rural, politicalLeaning: 0.6),
    USState(id: "TX", name: "Texas", population: 29145505, centerX: 0.40, centerY: 0.22, neighbors: ["OK", "AR", "LA", "NM"], type: .swing, politicalLeaning: 0.2),
    
    // Great Plains
    USState(id: "ND", name: "North Dakota", population: 779094, centerX: 0.45, centerY: 0.82, neighbors: ["MN", "SD", "MT"], type: .rural, politicalLeaning: 0.6),
    USState(id: "SD", name: "South Dakota", population: 886667, centerX: 0.45, centerY: 0.72, neighbors: ["ND", "MN", "IA", "NE", "WY", "MT"], type: .rural, politicalLeaning: 0.5),
    USState(id: "NE", name: "Nebraska", population: 1961504, centerX: 0.42, centerY: 0.60, neighbors: ["SD", "IA", "MO", "KS", "CO", "WY"], type: .rural, politicalLeaning: 0.4),
    USState(id: "KS", name: "Kansas", population: 2937880, centerX: 0.42, centerY: 0.50, neighbors: ["NE", "MO", "OK", "CO"], type: .rural, politicalLeaning: 0.4),
    
    // Mountain West
    USState(id: "MT", name: "Montana", population: 1084225, centerX: 0.28, centerY: 0.85, neighbors: ["ND", "SD", "WY", "ID"], type: .rural, politicalLeaning: 0.3),
    USState(id: "WY", name: "Wyoming", population: 576851, centerX: 0.30, centerY: 0.70, neighbors: ["MT", "SD", "NE", "CO", "UT", "ID"], type: .rural, politicalLeaning: 0.6),
    USState(id: "CO", name: "Colorado", population: 5773714, centerX: 0.32, centerY: 0.55, neighbors: ["WY", "NE", "KS", "OK", "NM", "AZ", "UT"], type: .swing, politicalLeaning: -0.1),
    USState(id: "NM", name: "New Mexico", population: 2117522, centerX: 0.28, centerY: 0.38, neighbors: ["CO", "OK", "TX", "AZ"], type: .suburban, politicalLeaning: -0.2),
    USState(id: "AZ", name: "Arizona", population: 7278717, centerX: 0.20, centerY: 0.35, neighbors: ["NM", "CO", "UT", "NV", "CA"], type: .swing, politicalLeaning: 0.1),
    USState(id: "UT", name: "Utah", population: 3271616, centerX: 0.22, centerY: 0.55, neighbors: ["WY", "CO", "AZ", "NV", "ID"], type: .suburban, politicalLeaning: 0.5),
    USState(id: "ID", name: "Idaho", population: 1839106, centerX: 0.20, centerY: 0.75, neighbors: ["MT", "WY", "UT", "NV", "OR", "WA"], type: .rural, politicalLeaning: 0.5),
    USState(id: "NV", name: "Nevada", population: 3104614, centerX: 0.15, centerY: 0.52, neighbors: ["ID", "UT", "AZ", "CA", "OR"], type: .swing, politicalLeaning: -0.1),
    
    // Pacific
    USState(id: "WA", name: "Washington", population: 7614893, centerX: 0.12, centerY: 0.88, neighbors: ["ID", "OR"], type: .urban, politicalLeaning: -0.4),
    USState(id: "OR", name: "Oregon", population: 4237256, centerX: 0.10, centerY: 0.78, neighbors: ["WA", "ID", "NV", "CA"], type: .suburban, politicalLeaning: -0.3),
    USState(id: "CA", name: "California", population: 39538223, centerX: 0.08, centerY: 0.45, neighbors: ["OR", "NV", "AZ"], type: .urban, politicalLeaning: -0.5),
    
    // Non-contiguous (positioned in corners for visibility)
    USState(id: "AK", name: "Alaska", population: 733391, centerX: 0.12, centerY: 0.12, neighbors: [], type: .rural, politicalLeaning: 0.3),
    USState(id: "HI", name: "Hawaii", population: 1455271, centerX: 0.22, centerY: 0.08, neighbors: [], type: .suburban, politicalLeaning: -0.4),
]

// MARK: - Influence Vectors

enum InfluenceVector: String, CaseIterable, Identifiable {
    case grassroots = "Grassroots"
    case socialMedia = "Social Media"
    case mainstream = "Mainstream Media"
    case institutions = "Institutions"
    case culture = "Culture"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .grassroots: return "person.3.fill"
        case .socialMedia: return "bubble.left.and.bubble.right.fill"
        case .mainstream: return "tv.fill"
        case .institutions: return "building.columns.fill"
        case .culture: return "theatermasks.fill"
        }
    }
    
    var baseSpreadRate: Float {
        switch self {
        case .grassroots: return 0.06
        case .socialMedia: return 0.18
        case .mainstream: return 0.12
        case .institutions: return 0.08
        case .culture: return 0.04
        }
    }
    
    var visibilityImpact: Float {
        switch self {
        case .grassroots: return 0.03
        case .socialMedia: return 0.12
        case .mainstream: return 0.20
        case .institutions: return 0.15
        case .culture: return 0.05
        }
    }
}

// MARK: - State Region (Game State for each US State)

class StateRegion: Identifiable, ObservableObject {
    let id: String
    let stateData: USState
    
    let totalPopulation: Int
    @Published var unconvinced: Int
    @Published var ideaAdopters: Int = 0
    @Published var counterAdopters: Int = 0
    @Published var disengaged: Int = 0
    
    @Published var isDiscovered: Bool = false
    @Published var mediaAttention: Float = 0
    @Published var socialUnrest: Float = 0
    @Published var echoChambered: Bool = false
    
    
    // Add this inside the StateRegion class after the other computed properties


  
    var ideaAdoptionRate: Float {
        guard totalPopulation > 0 else { return 0 }
        return Float(ideaAdopters) / Float(totalPopulation)
    }
    
    var counterAdoptionRate: Float {
        guard totalPopulation > 0 else { return 0 }
        return Float(counterAdopters) / Float(totalPopulation)
    }
    
    var contestedRate: Float {
        guard totalPopulation > 0 else { return 0 }
        return Float(unconvinced) / Float(totalPopulation)
    }
    
    var dominantIdea: String {
        if ideaAdopters > counterAdopters * 2 { return "idea" }
        if counterAdopters > ideaAdopters * 2 { return "counter" }
        return "contested"
    }
    
    init(stateData: USState) {
        self.id = stateData.id
        self.stateData = stateData
        self.totalPopulation = stateData.population
        self.unconvinced = stateData.population
    }
    
    func adoptIdea(count: Int) {
        let actual = min(count, unconvinced)
        unconvinced -= actual
        ideaAdopters += actual
    }
    
    func adoptCounter(count: Int) {
        let actual = min(count, unconvinced)
        unconvinced -= actual
        counterAdopters += actual
    }
    
    func convertToIdea(count: Int) {
        let actual = min(count, counterAdopters)
        counterAdopters -= actual
        ideaAdopters += actual
    }
    
    func convertToCounter(count: Int) {
        let actual = min(count, ideaAdopters)
        ideaAdopters -= actual
        counterAdopters += actual
    }
    
    func disengage(count: Int) {
        let fromIdea = min(count / 2, ideaAdopters)
        let fromCounter = min(count / 2, counterAdopters)
        ideaAdopters -= fromIdea
        counterAdopters -= fromCounter
        disengaged += fromIdea + fromCounter
    }
    
    var statusMessage: String {
        if ideaAdoptionRate > 0.7 {
            return ["The idea dominates conversation here.", "Almost everyone has embraced it.", "Complete transformation."].randomElement()!
        } else if ideaAdoptionRate > 0.4 {
            return ["The movement grows stronger.", "More join every day.", "Momentum building."].randomElement()!
        } else if counterAdoptionRate > 0.5 {
            return ["Strong resistance here.", "The backlash is fierce.", "Opposition organized."].randomElement()!
        } else if socialUnrest > 0.5 {
            return ["Tensions run high.", "Communities divided.", "Heated debates everywhere."].randomElement()!
        } else if ideaAdoptionRate > 0.1 {
            return ["The idea is taking root.", "People are talking.", "Early signs of change."].randomElement()!
        } else if echoChambered {
            return ["A protected community.", "Information flows one way.", "Believers stay believers."].randomElement()!
        } else {
            return ["Life goes on as usual.", "No sign of change yet.", "Quiet, for now."].randomElement()!
        }
    }
    
}

// MARK: - USA (Game World)

class USA: ObservableObject {
    let difficulty: GameDifficulty
    
    @Published var states: [String: StateRegion] = [:]
    @Published var gameTime: Int = 0
    @Published var influencePoints: Int = 0
    
    @Published var globalIdeaAdoption: Float = 0
    @Published var globalCounterAdoption: Float = 0
    @Published var globalDisengaged: Float = 0
    
    @Published var counterIdeaActive: Bool = false
    @Published var counterIdeaStrength: Float = 0
    
    @Published var vectorLevels: [InfluenceVector: Float] = [
        .grassroots: 0.1,
        .socialMedia: 0,
        .mainstream: 0,
        .institutions: 0,
        .culture: 0
    ]
    
    @Published var purchasedUpgrades: Set<String> = []
    
    var spreadBonus: Float = 0
    var echoStrength: Float = 0
    var culturalResilience: Float = 0
    
    @Published var gameState: GameState = .playing
    
    enum GameState {
        case playing
        case ideaWins
        case counterWins
        case coexistence
        case collapse
    }
    
    var allStates: [StateRegion] { Array(states.values) }
    var totalPopulation: Int { allStates.reduce(0) { $0 + $1.totalPopulation } }
    
    init(difficulty: GameDifficulty) {
        self.difficulty = difficulty
        
        for stateData in usStatesData {
            states[stateData.id] = StateRegion(stateData: stateData)
        }
    }
    
    func getState(_ id: String) -> StateRegion? {
        states[id]
    }
    
    func getNeighbors(of state: StateRegion) -> [StateRegion] {
        state.stateData.neighbors.compactMap { states[$0] }
    }
    
    func updateGlobalStats() {
        let total = Float(totalPopulation)
        globalIdeaAdoption = Float(allStates.reduce(0) { $0 + $1.ideaAdopters }) / total
        globalCounterAdoption = Float(allStates.reduce(0) { $0 + $1.counterAdopters }) / total
        globalDisengaged = Float(allStates.reduce(0) { $0 + $1.disengaged }) / total
    }
}

// MARK: - Game Difficulty

enum GameDifficulty: String, CaseIterable, Identifiable {
    case tippingPoint = "Tipping Point"
    case culturalDominance = "Cultural Dominance"
    case totalShift = "Total Shift"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .tippingPoint: return "Reach 60% adoption."
        case .culturalDominance: return "Reach 80% adoption."
        case .totalShift: return "Complete national adoption."
        }
    }
    
    var winThreshold: Float {
        switch self {
        case .tippingPoint: return 0.6
        case .culturalDominance: return 0.8
        case .totalShift: return 0.95
        }
    }
    
    var counterLoseThreshold: Float {
        switch self {
        case .tippingPoint: return 0.4
        case .culturalDominance: return 0.2
        case .totalShift: return 0.05
        }
    }
    
    var counterSpeedMultiplier: Float {
        switch self {
        case .tippingPoint: return 0.7
        case .culturalDominance: return 1.0
        case .totalShift: return 1.4
        }
    }
}

// MARK: - News Events

struct NewsEvent: Identifiable {
    let id = UUID()
    let headline: String
    let source: String
    let type: EventType
    let stateId: String?
    let timestamp: Int
    
    enum EventType {
        case spread
        case counter
        case milestone
        case backlash
        case cultural
        case political
        case warning
    }
}

// News sources for realism
let newsSources = [
    "Associated Press", "Reuters", "NPR", "CNN", "Fox News", "MSNBC",
    "The New York Times", "Washington Post", "Wall Street Journal",
    "Local News", "Social Media", "Viral Post", "Podcast", "University Study"
]

// MARK: - Upgrades

enum UpgradeCategory: String, CaseIterable {
    case vectors = "Vectors"
    case expression = "Expression"
    case resilience = "Resilience"
}

struct Upgrade: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let category: UpgradeCategory
    let cost: Int
    let prerequisites: [String]
    let effects: [UpgradeEffect]
    let icon: String
    
    enum UpgradeEffect {
        case vectorBoost(InfluenceVector, Float)
        case spreadBonus(Float)
        case echoStrength(Float)
        case culturalResilience(Float)
        case reduceVisibility(Float)
        case convertPower(Float)
        case stabilize(Float)
    }
}

let vectorUpgrades: [Upgrade] = [
    // Grassroots
    Upgrade(name: "Community Organizers", description: "Local leaders spread the word", category: .vectors, cost: 6, prerequisites: [], effects: [.vectorBoost(.grassroots, 0.12)], icon: "person.3.fill"),
    Upgrade(name: "Door to Door", description: "Personal conversations change minds", category: .vectors, cost: 10, prerequisites: ["Community Organizers"], effects: [.vectorBoost(.grassroots, 0.20), .spreadBonus(0.05)], icon: "door.left.hand.open"),
    
    // Social Media
    Upgrade(name: "Viral Content", description: "Shareable posts spread fast", category: .vectors, cost: 8, prerequisites: [], effects: [.vectorBoost(.socialMedia, 0.15)], icon: "arrow.up.right.circle.fill"),
    Upgrade(name: "Influencer Network", description: "Key voices amplify the message", category: .vectors, cost: 14, prerequisites: ["Viral Content"], effects: [.vectorBoost(.socialMedia, 0.25), .spreadBonus(0.08)], icon: "star.fill"),
    Upgrade(name: "Algorithm Gaming", description: "The feed favors your content", category: .vectors, cost: 20, prerequisites: ["Influencer Network"], effects: [.vectorBoost(.socialMedia, 0.35), .echoStrength(0.1)], icon: "chart.line.uptrend.xyaxis"),
    
    // Mainstream Media
    Upgrade(name: "Press Coverage", description: "Journalists take notice", category: .vectors, cost: 10, prerequisites: [], effects: [.vectorBoost(.mainstream, 0.12)], icon: "newspaper.fill"),
    Upgrade(name: "Talking Heads", description: "Pundits debate your idea", category: .vectors, cost: 16, prerequisites: ["Press Coverage"], effects: [.vectorBoost(.mainstream, 0.22), .reduceVisibility(-0.1)], icon: "person.wave.2.fill"),
    Upgrade(name: "Documentary", description: "A film captures the movement", category: .vectors, cost: 22, prerequisites: ["Talking Heads"], effects: [.vectorBoost(.mainstream, 0.30), .vectorBoost(.culture, 0.1)], icon: "film.fill"),
    
    // Institutions
    Upgrade(name: "Academic Support", description: "Researchers publish findings", category: .vectors, cost: 12, prerequisites: [], effects: [.vectorBoost(.institutions, 0.15)], icon: "graduationcap.fill"),
    Upgrade(name: "Policy Papers", description: "Think tanks advocate", category: .vectors, cost: 18, prerequisites: ["Academic Support"], effects: [.vectorBoost(.institutions, 0.25), .stabilize(0.1)], icon: "doc.text.fill"),
    Upgrade(name: "Legislative Push", description: "Politicians champion the cause", category: .vectors, cost: 25, prerequisites: ["Policy Papers"], effects: [.vectorBoost(.institutions, 0.35), .convertPower(0.1)], icon: "building.columns.fill"),
    
    // Culture
    Upgrade(name: "Artistic Expression", description: "Art reflects the idea", category: .vectors, cost: 10, prerequisites: [], effects: [.vectorBoost(.culture, 0.15)], icon: "paintbrush.fill"),
    Upgrade(name: "Music & Anthems", description: "Songs carry the message", category: .vectors, cost: 15, prerequisites: ["Artistic Expression"], effects: [.vectorBoost(.culture, 0.25), .culturalResilience(0.15)], icon: "music.note"),
    Upgrade(name: "Generational Identity", description: "Youth grow up believing", category: .vectors, cost: 24, prerequisites: ["Music & Anthems"], effects: [.vectorBoost(.culture, 0.40), .culturalResilience(0.30)], icon: "figure.2.and.child.holdinghands"),
]

let expressionUpgrades: [Upgrade] = [
    Upgrade(name: "Quiet Confidence", description: "Believers don't need to shout", category: .expression, cost: 7, prerequisites: [], effects: [.reduceVisibility(0.15), .spreadBonus(0.03)], icon: "eye.slash"),
    Upgrade(name: "Proud Display", description: "Visible identity emerges", category: .expression, cost: 12, prerequisites: [], effects: [.spreadBonus(0.12), .convertPower(0.05)], icon: "flag.fill"),
    Upgrade(name: "Mass Rallies", description: "Crowds gather publicly", category: .expression, cost: 18, prerequisites: ["Proud Display"], effects: [.spreadBonus(0.18), .convertPower(0.12), .reduceVisibility(-0.15)], icon: "person.3.sequence.fill"),
]

let resilienceUpgrades: [Upgrade] = [
    Upgrade(name: "Echo Chambers", description: "Believers insulate from doubt", category: .resilience, cost: 10, prerequisites: [], effects: [.echoStrength(0.20)], icon: "repeat.circle.fill"),
    Upgrade(name: "Tribal Identity", description: "The idea becomes who they are", category: .resilience, cost: 16, prerequisites: ["Echo Chambers"], effects: [.echoStrength(0.35), .culturalResilience(0.15)], icon: "person.crop.circle.badge.checkmark"),
    Upgrade(name: "Narrative Immunity", description: "Facts don't change minds", category: .resilience, cost: 22, prerequisites: ["Tribal Identity"], effects: [.echoStrength(0.50), .stabilize(0.15)], icon: "shield.lefthalf.filled"),
    
    Upgrade(name: "Deep Roots", description: "Woven into daily life", category: .resilience, cost: 14, prerequisites: [], effects: [.culturalResilience(0.25)], icon: "leaf.fill"),
    Upgrade(name: "Institutional Capture", description: "Systems enforce the idea", category: .resilience, cost: 28, prerequisites: ["Deep Roots"], effects: [.culturalResilience(0.40), .convertPower(0.15)], icon: "building.2.fill"),
]

let allUpgrades: [Upgrade] = vectorUpgrades + expressionUpgrades + resilienceUpgrades
