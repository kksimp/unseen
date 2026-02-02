import Foundation
import Combine
import SceneKit

class GameViewModel: ObservableObject {
    @Published var currentScreen: GameScreen = .menu
    @Published var selectedScenario: GameScenario?
    @Published var selectedDifficulty: GameDifficulty = .culturalDominance
    @Published var usa: USA?
    @Published var simulation: SimulationEngine?
    @Published var selectedState: StateRegion?
    @Published var showUpgrades: Bool = false
    @Published var showEndScreen: Bool = false
    @Published var isPaused: Bool = false
    @Published var hasActiveSave: Bool = false
    @Published var showPauseMenu: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var autoSaveTimer: Timer?
    
    enum GameScreen {
        case menu
        case difficultySelect
        case game
        case endGame
    }
    
    // Scenarios affect starting conditions
    enum GameScenario: String, CaseIterable, Identifiable {
        case grassroots = "Grassroots"
        case viralMoment = "Viral Moment"
        case mediaPush = "Media Push"
        case institutionalBacking = "Institutional"
        case culturalMovement = "Cultural Wave"
        case random = "Unknown Origin"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .grassroots: return "Start with strong local networks"
            case .viralMoment: return "Begin with social media momentum"
            case .mediaPush: return "Launch with press coverage"
            case .institutionalBacking: return "Academic and policy support"
            case .culturalMovement: return "Artists lead the way"
            case .random: return "Unpredictable origin"
            }
        }
        
        var icon: String {
            switch self {
            case .grassroots: return "person.3.fill"
            case .viralMoment: return "bubble.left.and.bubble.right.fill"
            case .mediaPush: return "tv.fill"
            case .institutionalBacking: return "building.columns.fill"
            case .culturalMovement: return "theatermasks.fill"
            case .random: return "dice.fill"
            }
        }
        
        var startingVectors: [InfluenceVector: Float] {
            switch self {
            case .grassroots: return [.grassroots: 0.25, .socialMedia: 0.05]
            case .viralMoment: return [.socialMedia: 0.30, .grassroots: 0.05]
            case .mediaPush: return [.mainstream: 0.25, .socialMedia: 0.10]
            case .institutionalBacking: return [.institutions: 0.25, .mainstream: 0.10]
            case .culturalMovement: return [.culture: 0.25, .socialMedia: 0.10]
            case .random:
                let vectors = InfluenceVector.allCases
                var result: [InfluenceVector: Float] = [:]
                for vector in vectors {
                    result[vector] = Float.random(in: 0...0.20)
                }
                return result
            }
        }
        
        var suggestedStartState: String {
            switch self {
            case .grassroots: return "IA"  // Iowa - heartland organizing
            case .viralMoment: return "CA"  // California - tech hub
            case .mediaPush: return "NY"   // New York - media center
            case .institutionalBacking: return "MA"  // Massachusetts - academia
            case .culturalMovement: return "TN"  // Tennessee - music/culture
            case .random: return ["CA", "TX", "FL", "NY", "IL", "PA"].randomElement()!
            }
        }
    }
    
    var hasSeeded: Bool {
        usa?.allStates.contains { $0.ideaAdopters > 0 } ?? false
    }
    
    init() {
        hasActiveSave = SaveManager.shared.hasActiveSave()
    }
    
    // MARK: - Game Flow
    
    func selectScenario(_ scenario: GameScenario) {
        selectedScenario = scenario
        startGame()
    }
    
    func startGame() {
        guard let scenario = selectedScenario else { return }
        
        let newUSA = USA(difficulty: selectedDifficulty)
        
        // Apply scenario starting vectors
        for (vector, level) in scenario.startingVectors {
            newUSA.vectorLevels[vector] = level
        }
        
        // Give starting influence points based on difficulty
        switch selectedDifficulty {
        case .tippingPoint: newUSA.influencePoints = 15
        case .culturalDominance: newUSA.influencePoints = 10
        case .totalShift: newUSA.influencePoints = 5
        }
        
        self.usa = newUSA
        self.simulation = SimulationEngine(usa: newUSA)
        self.currentScreen = .game
        self.selectedState = nil
        self.showUpgrades = false
        self.showEndScreen = false
        self.isPaused = false
        self.showPauseMenu = false
        
        // Auto-seed suggested state after opening
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            if let startState = self.usa?.getState(scenario.suggestedStartState) {
                self.simulation?.seedState(startState)
            }
            self.simulation?.start()
            self.startAutoSave()
        }
        
        // Watch for game end
        simulation?.$usa
            .compactMap { $0 }
            .sink { [weak self] usa in
                if usa.gameState != .playing {
                    self?.handleGameEnd()
                }
            }
            .store(in: &cancellables)
    }
    
    func continueGame() {
        guard let save = SaveManager.shared.loadGame() else { return }
        
        let difficulty = GameDifficulty.allCases.first { $0.rawValue == save.difficulty } ?? .culturalDominance
        let newUSA = USA(difficulty: difficulty)
        
        // Restore USA state
        newUSA.gameTime = save.gameTime
        newUSA.influencePoints = save.influencePoints
        newUSA.counterIdeaActive = save.counterIdeaActive
        newUSA.counterIdeaStrength = save.counterIdeaStrength
        newUSA.spreadBonus = save.spreadBonus
        newUSA.echoStrength = save.echoStrength
        newUSA.culturalResilience = save.culturalResilience
        newUSA.purchasedUpgrades = Set(save.purchasedUpgrades)
        
        // Restore vector levels
        for (vectorName, level) in save.vectorLevels {
            if let vector = InfluenceVector.allCases.first(where: { $0.rawValue == vectorName }) {
                newUSA.vectorLevels[vector] = level
            }
        }
        
        // Restore state data
        for stateSave in save.states {
            if let state = newUSA.getState(stateSave.id) {
                state.unconvinced = stateSave.unconvinced
                state.ideaAdopters = stateSave.ideaAdopters
                state.counterAdopters = stateSave.counterAdopters
                state.disengaged = stateSave.disengaged
                state.echoChambered = stateSave.echoChambered
                state.socialUnrest = stateSave.socialUnrest
                state.mediaAttention = stateSave.mediaAttention
            }
        }
        
        newUSA.updateGlobalStats()
        
        self.usa = newUSA
        self.simulation = SimulationEngine(usa: newUSA)
        self.selectedScenario = .random  // We don't save scenario, just use placeholder
        self.selectedDifficulty = difficulty
        
        self.currentScreen = .game
        self.selectedState = nil
        self.showUpgrades = false
        self.showEndScreen = false
        self.isPaused = false
        self.showPauseMenu = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.simulation?.start()
            self?.startAutoSave()
        }
        
        simulation?.$usa
            .compactMap { $0 }
            .sink { [weak self] usa in
                if usa.gameState != .playing {
                    self?.handleGameEnd()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleGameEnd() {
        stopAutoSave()
        showEndScreen = true
        
        if let usa = usa {
            SaveManager.shared.saveHighScore(usa: usa)
        }
        
        SaveManager.shared.clearActiveSave()
        hasActiveSave = false
    }
    
    func restartGame() {
        simulation?.pause()
        stopAutoSave()
        SaveManager.shared.clearActiveSave()
        startGame()
    }
    
    func returnToMenu() {
        simulation?.pause()
        stopAutoSave()
        saveCurrentGame()
        
        usa = nil
        simulation = nil
        selectedScenario = nil
        selectedState = nil
        currentScreen = .menu
        showPauseMenu = false
        hasActiveSave = SaveManager.shared.hasActiveSave()
    }
    
    func returnToDifficultySelect() {
        simulation?.pause()
        stopAutoSave()
        saveCurrentGame()
        
        usa = nil
        simulation = nil
        selectedState = nil
        currentScreen = .difficultySelect
        showPauseMenu = false
        hasActiveSave = SaveManager.shared.hasActiveSave()
    }
    
    func togglePause() {
        isPaused.toggle()
        showPauseMenu = isPaused
        if isPaused {
            simulation?.pause()
            saveCurrentGame()
        } else {
            simulation?.start()
        }
    }
    
    func resumeGame() {
        isPaused = false
        showPauseMenu = false
        simulation?.start()
    }
    
    func saveAndQuit() {
        simulation?.pause()
        stopAutoSave()
        saveCurrentGame()
        
        usa = nil
        simulation = nil
        selectedScenario = nil
        selectedState = nil
        currentScreen = .menu
        showPauseMenu = false
        hasActiveSave = SaveManager.shared.hasActiveSave()
    }
    
    // MARK: - Auto Save
    
    private func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.saveCurrentGame()
        }
    }
    
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func saveCurrentGame() {
        guard let usa = usa, let simulation = simulation, usa.gameState == .playing else { return }
        SaveManager.shared.saveGame(usa: usa, simulation: simulation)
        hasActiveSave = true
    }
    
    // MARK: - Player Actions
    
    func selectState(_ state: StateRegion) {
        selectedState = state
    }
    
    func deselectState() {
        selectedState = nil
    }
    
    func seedSelectedState() {
        guard let state = selectedState else { return }
        guard !hasSeeded else { return }
        simulation?.seedState(state)
    }
    
    func amplifySelectedState() {
        guard let state = selectedState else { return }
        simulation?.amplify(state)
    }
    
    func createEchoChamber() {
        guard let state = selectedState else { return }
        simulation?.createEchoChamber(state)
    }
    
    func purchaseUpgrade(_ upgrade: Upgrade) {
        simulation?.purchaseUpgrade(upgrade)
    }
    
    // MARK: - Computed Properties
    
    var canSeed: Bool {
        guard let state = selectedState else { return false }
        return !hasSeeded && state.ideaAdopters == 0
    }
    
    var canAmplify: Bool {
        guard let state = selectedState, let usa = usa else { return false }
        return usa.influencePoints >= 2 && state.ideaAdopters > 0
    }
    
    var canCreateEchoChamber: Bool {
        guard let state = selectedState, let usa = usa else { return false }
        return usa.influencePoints >= 3 &&
               state.ideaAdopters > state.totalPopulation / 10 &&
               !state.echoChambered
    }
    
    var availableUpgrades: [Upgrade] {
        guard let usa = usa else { return [] }
        return allUpgrades.filter { !usa.purchasedUpgrades.contains($0.name) }
    }
    
    var endGameTitle: String {
        guard let state = usa?.gameState else { return "" }
        switch state {
        case .ideaWins: return "Total Transformation"
        case .counterWins: return "Complete Rejection"
        case .coexistence: return "Divided Nation"
        case .collapse: return "Social Collapse"
        case .playing: return ""
        }
    }
    
    var endGameMessage: String {
        guard let state = usa?.gameState else { return "" }
        switch state {
        case .ideaWins: return "The idea became reality. America will never be the same."
        case .counterWins: return "The backlash was overwhelming. The movement fades into history."
        case .coexistence: return "Neither side won. Two Americas now exist side by side."
        case .collapse: return "The conflict tore the nation apart. Trust is gone."
        case .playing: return ""
        }
    }
    
    var currentScore: Int {
        guard let usa = usa else { return 0 }
        return SaveManager.shared.calculateScore(usa: usa)
    }
    
    func getHighScore() -> Int? {
        SaveManager.shared.getHighScores().first?.score
    }
}
