import Foundation
import Combine
import SceneKit

class GameViewModel: ObservableObject {
    @Published var currentScreen: GameScreen = .menu
    @Published var selectedScenario: CityScenario?
    @Published var city: City?
    @Published var simulation: SimulationEngine?
    @Published var selectedDistrict: District?
    @Published var showMutations: Bool = false
    @Published var showEndScreen: Bool = false
    @Published var isPaused: Bool = false
    @Published var hasActiveSave: Bool = false
    @Published var showPauseMenu: Bool = false  // NEW: For pause menu overlay
    
    private var cancellables = Set<AnyCancellable>()
    private var autoSaveTimer: Timer?
    
    enum GameScreen {
        case menu
        case citySelect
        case game
        case endGame
    }
    
    init() {
        hasActiveSave = SaveManager.shared.hasActiveSave()
    }
    
    // MARK: - Game Flow
    
    func selectCity(_ scenario: CityScenario) {
        selectedScenario = scenario
        startGame(scenario: scenario)
    }
    
    func startGame(scenario: CityScenario) {
        let newCity = City(scenario: scenario, gridSize: 12)  // CHANGED: Doubled grid size
        self.city = newCity
        self.simulation = SimulationEngine(city: newCity)
        self.currentScreen = .game
        self.selectedDistrict = nil
        self.showMutations = false
        self.showEndScreen = false
        self.isPaused = false
        self.showPauseMenu = false
        
        // Start simulation after opening line
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.simulation?.start()
            self?.startAutoSave()
        }
        
        // Watch for game end
        simulation?.$city
            .compactMap { $0 }
            .sink { [weak self] city in
                if city.gameState != .playing {
                    self?.handleGameEnd()
                }
            }
            .store(in: &cancellables)
    }
    
    func continueGame() {
        guard let save = SaveManager.shared.loadGame(),
              let scenario = CityScenario.allCases.first(where: { $0.rawValue == save.scenario }) else {
            return
        }
        
        // Restore city state
        let newCity = City(scenario: scenario, gridSize: save.gridSize)
        newCity.gameTime = save.gameTime
        newCity.dayPhase = SaveManager.shared.intToDayPhase(save.dayPhase)
        newCity.hasBeenSeeded = save.hasBeenSeeded  // Restore seed state
        
        // Restore district states
        for districtSave in save.districts {
            if let district = newCity.getDistrict(at: districtSave.gridX, y: districtSave.gridY) {
                district.density = districtSave.density
                district.stress = districtSave.stress
                district.resistance = districtSave.resistance
                district.connectivity = districtSave.connectivity
                district.influence = districtSave.influence
                district.activityLevel = districtSave.activityLevel
                district.suppressionLevel = districtSave.suppressionLevel
                district.isSeeded = districtSave.isSeeded
            }
        }
        
        self.city = newCity
        self.simulation = SimulationEngine(city: newCity)
        self.simulation?.mutationPoints = save.mutationPoints
        self.selectedScenario = scenario
        
        // Restore mutations
        for mutationName in save.activeMutationIds {
            if let mutation = availableMutations.first(where: { $0.name == mutationName }) {
                self.simulation?.activeMutations.append(mutation)
            }
        }
        
        self.currentScreen = .game
        self.selectedDistrict = nil
        self.showMutations = false
        self.showEndScreen = false
        self.isPaused = false
        self.showPauseMenu = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.simulation?.start()
            self?.startAutoSave()
        }
        
        // Watch for game end
        simulation?.$city
            .compactMap { $0 }
            .sink { [weak self] city in
                if city.gameState != .playing {
                    self?.handleGameEnd()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleGameEnd() {
        stopAutoSave()
        showEndScreen = true
        
        // Save high score
        if let city = city {
            SaveManager.shared.saveHighScore(city: city, outcome: city.gameState)
        }
        
        // Clear active save
        SaveManager.shared.clearActiveSave()
        hasActiveSave = false
    }
    
    func restartGame() {
        guard let scenario = selectedScenario else { return }
        simulation?.pause()
        stopAutoSave()
        SaveManager.shared.clearActiveSave()
        startGame(scenario: scenario)
    }
    
    func returnToMenu() {
        simulation?.pause()
        stopAutoSave()
        saveCurrentGame()
        
        city = nil
        simulation = nil
        selectedScenario = nil
        selectedDistrict = nil
        currentScreen = .menu
        showPauseMenu = false
        hasActiveSave = SaveManager.shared.hasActiveSave()
    }
    
    func returnToCitySelect() {
        simulation?.pause()
        stopAutoSave()
        saveCurrentGame()
        
        city = nil
        simulation = nil
        selectedDistrict = nil
        currentScreen = .citySelect
        showPauseMenu = false
        hasActiveSave = SaveManager.shared.hasActiveSave()
    }
    
    func togglePause() {
        isPaused.toggle()
        showPauseMenu = isPaused  // Show menu when paused
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
        
        city = nil
        simulation = nil
        selectedScenario = nil
        selectedDistrict = nil
        currentScreen = .menu
        showPauseMenu = false
        hasActiveSave = SaveManager.shared.hasActiveSave()
    }
    
    // MARK: - Auto Save
    
    private func startAutoSave() {
        let settings = SaveManager.shared.getSettings()
        guard settings.autoSaveEnabled else { return }
        
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.saveCurrentGame()
        }
    }
    
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func saveCurrentGame() {
        guard let city = city, let simulation = simulation, city.gameState == .playing else { return }
        SaveManager.shared.saveGame(city: city, simulation: simulation)
        hasActiveSave = true
    }
    
    // MARK: - Player Actions
    
    func selectDistrict(_ district: District) {
        selectedDistrict = district
    }
    
    func deselectDistrict() {
        selectedDistrict = nil
    }
    
    func seedSelectedDistrict() {
        guard let district = selectedDistrict else { return }
        simulation?.seedDistrict(district)
    }
    
    func disturbSelectedDistrict() {
        guard let district = selectedDistrict else { return }
        simulation?.disturbDistrict(district)
    }
    
    func suppressSelectedDistrict() {
        guard let district = selectedDistrict else { return }
        simulation?.suppressDistrict(district)
    }
    
    func applyMutation(_ mutation: Mutation) {
        simulation?.applyMutation(mutation)
    }
    
    // MARK: - Computed Properties
    
    var availableMutationsForPurchase: [Mutation] {
        let applied = simulation?.activeMutations.map { $0.id } ?? []
        return availableMutations.filter { !applied.contains($0.id) }
    }
    
    // CHANGED: canSeed now checks if city has been seeded at all
    var canSeed: Bool {
        guard let district = selectedDistrict, let city = city else { return false }
        return !city.hasBeenSeeded && !district.isSeeded
    }
    
    var canDisturb: Bool {
        return (simulation?.mutationPoints ?? 0) >= 1
    }
    
    var canSuppress: Bool {
        return (simulation?.mutationPoints ?? 0) >= 1
    }
    
    var endGameTitle: String {
        guard let state = city?.gameState else { return "" }
        switch state {
        case .saturation: return "Total Saturation"
        case .coexistence: return "Strange Balance"
        case .collapse: return "System Collapse"
        case .eradication: return "Complete Eradication"
        case .playing: return ""
        }
    }
    
    var endGameMessage: String {
        guard let state = city?.gameState else { return "" }
        switch state {
        case .saturation: return "Whatever it was... it changed everything."
        case .coexistence: return "They learned to live with it."
        case .collapse: return "The city couldn't survive the strain."
        case .eradication: return "They stopped it. But at what cost?"
        case .playing: return ""
        }
    }
    
    var currentScore: Int {
        city?.score ?? 0
    }
    
    // NEW: Get seed info for pause menu
    var seedInfo: (district: District?, influence: Float, seededCount: Int, totalCount: Int)? {
        guard let city = city else { return nil }
        let seededDistrict = city.allDistricts.first { $0.isSeeded }
        let seededCount = city.allDistricts.filter { $0.isSeeded }.count
        return (seededDistrict, city.globalInfluence, seededCount, city.allDistricts.count)
    }
    
    func getHighScore(for scenario: CityScenario) -> Int? {
        SaveManager.shared.getHighScore(for: scenario)?.score
    }
    
    func getTimesPlayed(for scenario: CityScenario) -> Int {
        SaveManager.shared.getTimesPlayed(scenario)
    }
}
