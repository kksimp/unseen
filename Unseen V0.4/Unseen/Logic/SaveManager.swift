import Foundation

class SaveManager {
    static let shared = SaveManager()
    
    private let defaults = UserDefaults.standard
    
    private let activeGameKey = "unseen_active_game_v3"
    private let highScoresKey = "unseen_high_scores_v3"
    private let totalGamesPlayedKey = "unseen_total_games_v3"
    
    private init() {}
    
    // MARK: - Game Save Structure
    
    struct GameSave: Codable {
        let difficulty: String
        let ideaName: String?  // NEW: Save the idea name
        let gameTime: Int
        let influencePoints: Int
        let counterIdeaActive: Bool
        let counterIdeaStrength: Float
        let vectorLevels: [String: Float]
        let purchasedUpgrades: [String]
        let spreadBonus: Float
        let echoStrength: Float
        let culturalResilience: Float
        let states: [StateSave]
        let savedAt: Date
        
        struct StateSave: Codable {
            let id: String
            let unconvinced: Int
            let ideaAdopters: Int
            let counterAdopters: Int
            let disengaged: Int
            let echoChambered: Bool
            let socialUnrest: Float
            let mediaAttention: Float
        }
    }
    
    func saveGame(usa: USA, simulation: SimulationEngine) {
        let vectorLevels = Dictionary(uniqueKeysWithValues: usa.vectorLevels.map { ($0.key.rawValue, $0.value) })
        
        let stateSaves = usa.allStates.map { state in
            GameSave.StateSave(
                id: state.id,
                unconvinced: state.unconvinced,
                ideaAdopters: state.ideaAdopters,
                counterAdopters: state.counterAdopters,
                disengaged: state.disengaged,
                echoChambered: state.echoChambered,
                socialUnrest: state.socialUnrest,
                mediaAttention: state.mediaAttention
            )
        }
        
        let save = GameSave(
            difficulty: usa.difficulty.rawValue,
            ideaName: usa.ideaName?.name,  // Save the idea name
            gameTime: usa.gameTime,
            influencePoints: usa.influencePoints,
            counterIdeaActive: usa.counterIdeaActive,
            counterIdeaStrength: usa.counterIdeaStrength,
            vectorLevels: vectorLevels,
            purchasedUpgrades: Array(usa.purchasedUpgrades),
            spreadBonus: usa.spreadBonus,
            echoStrength: usa.echoStrength,
            culturalResilience: usa.culturalResilience,
            states: stateSaves,
            savedAt: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(save) {
            defaults.set(encoded, forKey: activeGameKey)
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
        var id: String { "\(difficulty)_\(date.timeIntervalSince1970)" }
        let difficulty: String
        let ideaName: String?  // Track which idea was used
        let outcome: String
        let score: Int
        let ideaAdoption: Float
        let counterAdoption: Float
        let timeElapsed: Int
        let date: Date
    }
    
    func saveHighScore(usa: USA) {
        var scores = getHighScores()
        
        let score = calculateScore(usa: usa)
        
        let newScore = HighScore(
            difficulty: usa.difficulty.rawValue,
            ideaName: usa.ideaName?.name,
            outcome: outcomeToString(usa.gameState),
            score: score,
            ideaAdoption: usa.globalIdeaAdoption,
            counterAdoption: usa.globalCounterAdoption,
            timeElapsed: usa.gameTime,
            date: Date()
        )
        
        scores.append(newScore)
        scores.sort { $0.score > $1.score }
        scores = Array(scores.prefix(50))
        
        if let encoded = try? JSONEncoder().encode(scores) {
            defaults.set(encoded, forKey: highScoresKey)
        }
        
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
    
    func calculateScore(usa: USA) -> Int {
        var score = 0
        
        // Base score for outcome
        switch usa.gameState {
        case .ideaWins: score += 1000
        case .coexistence: score += 500
        case .counterWins: score += 150
        case .collapse: score += 100
        case .playing: score += 0
        }
        
        // Bonus for adoption
        score += Int(usa.globalIdeaAdoption * 600)
        
        // Penalty for counter adoption
        score -= Int(usa.globalCounterAdoption * 200)
        
        // Speed bonus
        let speedBonus = max(0, 400 - usa.gameTime * 2)
        score += speedBonus
        
        // Difficulty multiplier
        switch usa.difficulty {
        case .tippingPoint: score = Int(Float(score) * 0.7)
        case .culturalDominance: score = Int(Float(score) * 1.0)
        case .totalShift: score = Int(Float(score) * 1.5)
        }
        
        // Penalty for disengaged
        score -= Int(usa.globalDisengaged * 300)
        
        return max(0, score)
    }
    
    func getTotalGamesPlayed() -> Int {
        return defaults.integer(forKey: totalGamesPlayedKey)
    }
    
    private func outcomeToString(_ outcome: USA.GameState) -> String {
        switch outcome {
        case .ideaWins: return "victory"
        case .counterWins: return "defeat"
        case .coexistence: return "divided"
        case .collapse: return "collapse"
        case .playing: return "playing"
        }
    }
    
    // MARK: - Reset
    
    func resetAllData() {
        defaults.removeObject(forKey: activeGameKey)
        defaults.removeObject(forKey: highScoresKey)
        defaults.removeObject(forKey: totalGamesPlayedKey)
    }
}
