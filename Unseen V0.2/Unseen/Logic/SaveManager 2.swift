import Foundation

class SaveManager {
    static let shared = SaveManager()
    
    private let defaults = UserDefaults.standard
    
    // Keys
    private let activeGameKey = "unseen_active_game"
    private let highScoresKey = "unseen_high_scores"
    private let completedCitiesKey = "unseen_completed_cities"
    private let totalGamesPlayedKey = "unseen_total_games"
    private let settingsKey = "unseen_settings"
    
    private init() {}
    
    // MARK: - Active Game Save/Load
    
    struct GameSave: Codable {
        let scenario: String
        let gridSize: Int
        let gameTime: Int
        let dayPhase: Int
        let mutationPoints: Int
        let activeMutationIds: [String]
        let districts: [DistrictSave]
        let savedAt: Date
        let hasBeenSeeded: Bool  // NEW: Track if city has been seeded
        
        struct DistrictSave: Codable {
            let gridX: Int
            let gridY: Int
            let type: String
            let density: Float
            let stress: Float
            let resistance: Float
            let connectivity: Float
            let influence: Float
            let activityLevel: Float
            let suppressionLevel: Float
            let isSeeded: Bool
        }
    }
    
    func saveGame(city: City, simulation: SimulationEngine) {
        let districtSaves = city.allDistricts.map { district in
            GameSave.DistrictSave(
                gridX: district.gridX,
                gridY: district.gridY,
                type: districtTypeToString(district.type),
                density: district.density,
                stress: district.stress,
                resistance: district.resistance,
                connectivity: district.connectivity,
                influence: district.influence,
                activityLevel: district.activityLevel,
                suppressionLevel: district.suppressionLevel,
                isSeeded: district.isSeeded
            )
        }
        
        let save = GameSave(
            scenario: city.scenario.rawValue,
            gridSize: city.gridSize,
            gameTime: city.gameTime,
            dayPhase: dayPhaseToInt(city.dayPhase),
            mutationPoints: simulation.mutationPoints,
            activeMutationIds: simulation.activeMutations.map { $0.name },
            districts: districtSaves,
            savedAt: Date(),
            hasBeenSeeded: city.hasBeenSeeded  // Save seed state
        )
        
        if let encoded = try? JSONEncoder().encode(save) {
            defaults.set(encoded, forKey: activeGameKey)
            print("Game saved successfully")
        }
    }
    
    func loadGame() -> GameSave? {
        guard let data = defaults.data(forKey: activeGameKey),
              let save = try? JSONDecoder().decode(GameSave.self, from: data) else {
            return nil
        }
        return save
    }
    
    func hasActiveSave() -> Bool {
        return defaults.data(forKey: activeGameKey) != nil
    }
    
    func clearActiveSave() {
        defaults.removeObject(forKey: activeGameKey)
    }
    
    // MARK: - High Scores
    
    struct HighScore: Codable, Identifiable {
        var id: String { "\(scenario)_\(date.timeIntervalSince1970)" }
        let scenario: String
        let outcome: String
        let score: Int
        let timeElapsed: Int
        let influenceReached: Float
        let date: Date
    }
    
    func saveHighScore(city: City, outcome: City.GameState) {
        var scores = getHighScores()
        
        let score = calculateScore(city: city, outcome: outcome)
        
        let newScore = HighScore(
            scenario: city.scenario.rawValue,
            outcome: outcomeToString(outcome),
            score: score,
            timeElapsed: city.gameTime,
            influenceReached: city.globalInfluence,
            date: Date()
        )
        
        scores.append(newScore)
        
        // Keep top 100 scores
        scores.sort { $0.score > $1.score }
        scores = Array(scores.prefix(100))
        
        if let encoded = try? JSONEncoder().encode(scores) {
            defaults.set(encoded, forKey: highScoresKey)
        }
        
        // Track completed cities
        markCityCompleted(city.scenario, outcome: outcome)
        
        // Increment games played
        let gamesPlayed = defaults.integer(forKey: totalGamesPlayedKey)
        defaults.set(gamesPlayed + 1, forKey: totalGamesPlayedKey)
    }
    
    func getHighScores() -> [HighScore] {
        guard let data = defaults.data(forKey: highScoresKey),
              let scores = try? JSONDecoder().decode([HighScore].self, from: data) else {
            return []
        }
        return scores
    }
    
    func getHighScore(for scenario: CityScenario) -> HighScore? {
        return getHighScores()
            .filter { $0.scenario == scenario.rawValue }
            .max { $0.score < $1.score }
    }
    
    func getBestOutcome(for scenario: CityScenario) -> String? {
        return getHighScore(for: scenario)?.outcome
    }
    
    private func calculateScore(city: City, outcome: City.GameState) -> Int {
        var score = 0
        
        // Base score for outcome
        switch outcome {
        case .saturation:
            score += 1000
        case .coexistence:
            score += 750
        case .collapse:
            score += 250
        case .eradication:
            score += 100
        case .playing:
            score += 0
        }
        
        // Bonus for influence reached
        score += Int(city.globalInfluence * 500)
        
        // Bonus for speed (faster = more points)
        let speedBonus = max(0, 500 - city.gameTime * 2)
        score += speedBonus
        
        // Bonus for low suppression at end
        let stealthBonus = Int((1.0 - city.globalSuppression) * 200)
        score += stealthBonus
        
        return score
    }
    
    // MARK: - Completed Cities
    
    struct CityCompletion: Codable {
        let scenario: String
        var outcomes: [String]
        var bestScore: Int
        var timesPlayed: Int
    }
    
    func markCityCompleted(_ scenario: CityScenario, outcome: City.GameState) {
        var completions = getCompletedCities()
        
        let outcomeStr = outcomeToString(outcome)
        
        if let index = completions.firstIndex(where: { $0.scenario == scenario.rawValue }) {
            var completion = completions[index]
            if !completion.outcomes.contains(outcomeStr) {
                completion.outcomes.append(outcomeStr)
            }
            completion.timesPlayed += 1
            completions[index] = completion
        } else {
            completions.append(CityCompletion(
                scenario: scenario.rawValue,
                outcomes: [outcomeStr],
                bestScore: 0,
                timesPlayed: 1
            ))
        }
        
        if let encoded = try? JSONEncoder().encode(completions) {
            defaults.set(encoded, forKey: completedCitiesKey)
        }
    }
    
    func getCompletedCities() -> [CityCompletion] {
        guard let data = defaults.data(forKey: completedCitiesKey),
              let completions = try? JSONDecoder().decode([CityCompletion].self, from: data) else {
            return []
        }
        return completions
    }
    
    func isCityCompleted(_ scenario: CityScenario) -> Bool {
        return getCompletedCities().contains { $0.scenario == scenario.rawValue }
    }
    
    func getTimesPlayed(_ scenario: CityScenario) -> Int {
        return getCompletedCities().first { $0.scenario == scenario.rawValue }?.timesPlayed ?? 0
    }
    
    // MARK: - Statistics
    
    func getTotalGamesPlayed() -> Int {
        return defaults.integer(forKey: totalGamesPlayedKey)
    }
    
    func getTotalCitiesCompleted() -> Int {
        return getCompletedCities().count
    }
    
    // MARK: - Settings
    
    struct GameSettings: Codable {
        var soundEnabled: Bool = true
        var musicEnabled: Bool = true
        var hapticEnabled: Bool = true
        var autoSaveEnabled: Bool = true
    }
    
    func saveSettings(_ settings: GameSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: settingsKey)
        }
    }
    
    func getSettings() -> GameSettings {
        guard let data = defaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(GameSettings.self, from: data) else {
            return GameSettings()
        }
        return settings
    }
    
    // MARK: - Helpers
    
    private func districtTypeToString(_ type: DistrictType) -> String {
        switch type {
        case .residential: return "residential"
        case .commercial: return "commercial"
        case .industrial: return "industrial"
        case .civic: return "civic"
        case .park: return "park"
        }
    }
    
    func stringToDistrictType(_ string: String) -> DistrictType {
        switch string {
        case "residential": return .residential
        case "commercial": return .commercial
        case "industrial": return .industrial
        case "civic": return .civic
        case "park": return .park
        default: return .residential
        }
    }
    
    private func dayPhaseToInt(_ phase: City.DayPhase) -> Int {
        switch phase {
        case .dawn: return 0
        case .day: return 1
        case .dusk: return 2
        case .night: return 3
        }
    }
    
    func intToDayPhase(_ value: Int) -> City.DayPhase {
        switch value {
        case 0: return .dawn
        case 1: return .day
        case 2: return .dusk
        case 3: return .night
        default: return .day
        }
    }
    
    private func outcomeToString(_ outcome: City.GameState) -> String {
        switch outcome {
        case .saturation: return "saturation"
        case .coexistence: return "coexistence"
        case .collapse: return "collapse"
        case .eradication: return "eradication"
        case .playing: return "playing"
        }
    }
    
    // MARK: - Reset (for testing)
    
    func resetAllData() {
        defaults.removeObject(forKey: activeGameKey)
        defaults.removeObject(forKey: highScoresKey)
        defaults.removeObject(forKey: completedCitiesKey)
        defaults.removeObject(forKey: totalGamesPlayedKey)
        defaults.removeObject(forKey: settingsKey)
    }
}
