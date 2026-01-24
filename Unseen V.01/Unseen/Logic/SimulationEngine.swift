import Foundation
import Combine

class SimulationEngine: ObservableObject {
    @Published var city: City
    @Published var events: [GameEvent] = []
    @Published var activeMutations: [Mutation] = []
    @Published var mutationPoints: Int = 0
    @Published var tickCount: Int = 0
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    let tickInterval: TimeInterval = 1.5  // Seconds between simulation ticks
    
    init(city: City) {
        self.city = city
    }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pause() {
        timer?.invalidate()
        timer = nil
    }
    
    func tick() {
        guard city.gameState == .playing else { return }
        
        tickCount += 1
        city.gameTime += 1
        
        // Update day/night cycle (every 20 ticks = new phase)
        updateDayPhase()
        
        // Process spread
        processSpread()
        
        // Process city response
        processResponse()
        
        // Update activity levels
        updateActivityLevels()
        
        // Check win/loss conditions
        checkGameState()
        
        // Award mutation points periodically
        if tickCount % 15 == 0 {
            mutationPoints += 1
            addEvent("Resources accumulating.", type: .observation)
        }
    }
    
    private func updateDayPhase() {
        let phase = (city.gameTime / 20) % 4
        switch phase {
        case 0: city.dayPhase = .dawn
        case 1: city.dayPhase = .day
        case 2: city.dayPhase = .dusk
        default: city.dayPhase = .night
        }
    }
    
    private func processSpread() {
        let seededDistricts = city.allDistricts.filter { $0.isSeeded && $0.influence > 0 }
        
        for district in seededDistricts {
            // Local spread within district
            let localSpread = calculateLocalSpread(for: district)
            district.influence = min(1.0, district.influence + localSpread)
            
            // Cross-district spread
            let neighbors = city.getNeighbors(of: district)
            for neighbor in neighbors {
                if shouldSpreadTo(neighbor, from: district) {
                    let crossSpread = calculateCrossSpread(from: district, to: neighbor)
                    if !neighbor.isSeeded && crossSpread > 0.05 {
                        neighbor.isSeeded = true
                        neighbor.influence = crossSpread
                        addEvent("Something reached \(neighbor.activityDescription.lowercased()) district.", type: .spread, districtId: neighbor.id)
                    } else if neighbor.isSeeded {
                        neighbor.influence = min(1.0, neighbor.influence + crossSpread * 0.5)
                    }
                }
            }
        }
        
        // Update global influence
        let totalInfluence = city.allDistricts.reduce(0.0) { $0 + $1.influence }
        city.globalInfluence = totalInfluence / Float(city.allDistricts.count)
    }
    
    private func calculateLocalSpread(for district: District) -> Float {
        var spread = city.config.spreadRate * 0.05
        
        // Day/night modifier
        if city.config.cycleDependent {
            spread *= city.dayPhase.activityMultiplier
        }
        
        // Resistance reduces spread
        spread *= (1.0 - district.resistance * 0.5)
        
        // Suppression reduces spread
        spread *= (1.0 - district.suppressionLevel * 0.7)
        
        // Apply mutations
        for mutation in activeMutations {
            switch mutation.effect {
            case .spreadBoost(let boost):
                spread *= (1.0 + boost)
            case .stealthBoost(let boost):
                if district.suppressionLevel < 0.3 {
                    spread *= (1.0 + boost)
                }
            case .stressFeeder(let boost):
                spread *= (1.0 + district.stress * boost)
            case .densityThriving(let boost):
                spread *= (1.0 + district.density * boost)
            case .suppressionResist(let resist):
                spread *= (1.0 + district.suppressionLevel * resist * 0.5)
            default:
                break
            }
        }
        
        // Add volatility
        let volatility = city.config.volatility
        spread *= Float.random(in: (1.0 - volatility)...(1.0 + volatility))
        
        return max(0, spread)
    }
    
    private func shouldSpreadTo(_ target: District, from source: District) -> Bool {
        let baseChance = source.influence * target.connectivity * city.config.connectivity
        let roll = Float.random(in: 0...1)
        return roll < baseChance
    }
    
    private func calculateCrossSpread(from source: District, to target: District) -> Float {
        var spread = source.influence * 0.1 * city.config.spreadRate
        
        // Connectivity bonus
        spread *= (source.connectivity + target.connectivity) / 2.0
        
        // Apply mutations
        for mutation in activeMutations {
            if case .connectivityExploit(let boost) = mutation.effect {
                spread *= (1.0 + boost)
            }
        }
        
        // Target resistance
        spread *= (1.0 - target.resistance * 0.3)
        
        return spread
    }
    
    private func processResponse() {
        let averageInfluence = city.globalInfluence
        var responseTriggered = false
        
        // Response threshold based on scenario
        var responseThreshold: Float = 0.15
        if city.config.lateResponseMultiplier > 1.0 {
            responseThreshold = 0.4  // Sunfall: late response
        }
        
        if averageInfluence > responseThreshold {
            responseTriggered = true
            
            // Increase suppression in affected districts
            for district in city.allDistricts where district.influence > 0.1 {
                let responseIncrease = city.config.responseSpeed * 0.03
                let adjustedResponse = responseIncrease * (city.config.lateResponseMultiplier > 1.0 && averageInfluence > 0.5 ? city.config.lateResponseMultiplier : 1.0)
                district.suppressionLevel = min(1.0, district.suppressionLevel + adjustedResponse)
                
                // Suppression increases resistance
                district.resistance = min(1.0, district.resistance + adjustedResponse * 0.2)
                
                // Suppression increases stress
                district.stress = min(1.0, district.stress + adjustedResponse * 0.1)
            }
        }
        
        // Suppression decay in unaffected areas
        for district in city.allDistricts where district.influence < 0.1 {
            district.suppressionLevel = max(0, district.suppressionLevel - 0.01)
        }
        
        // Update global suppression
        city.globalSuppression = city.allDistricts.reduce(0.0) { $0 + $1.suppressionLevel } / Float(city.allDistricts.count)
        
        // Event for response
        if responseTriggered && tickCount % 10 == 0 {
            addEvent("Increased presence in affected areas.", type: .response)
        }
        
        // Apply resistance reduction mutation
        for mutation in activeMutations {
            if case .resistanceReduction(let reduction) = mutation.effect {
                for district in city.allDistricts where district.influence > 0.2 {
                    district.resistance = max(0.1, district.resistance - reduction * 0.01)
                }
            }
        }
    }
    
    private func updateActivityLevels() {
        for district in city.allDistricts {
            var baseActivity = district.density * city.dayPhase.activityMultiplier
            
            // Influence changes behavior
            if district.influence > 0.5 {
                // High influence: erratic activity
                baseActivity *= Float.random(in: 0.3...1.2)
            } else if district.influence > 0.2 {
                // Moderate influence: slight changes
                baseActivity *= Float.random(in: 0.7...1.1)
            }
            
            // Suppression reduces activity
            baseActivity *= (1.0 - district.suppressionLevel * 0.6)
            
            // Stress affects activity
            if district.stress > 0.7 {
                baseActivity *= 0.5  // People stay home
            }
            
            // Volatility in Clearview
            if city.config.volatility > 0.7 && district.influence > 0.1 {
                baseActivity *= Float.random(in: 0.2...1.0)
            }
            
            // Retention in Edgeport
            if city.config.retention < 0.5 {
                district.influence *= city.config.retention + 0.3
            }
            
            district.activityLevel = max(0.05, min(1.0, baseActivity))
        }
    }
    
    private func checkGameState() {
        let avgInfluence = city.globalInfluence
        let avgSuppression = city.globalSuppression
        let maxInfluence = city.allDistricts.map { $0.influence }.max() ?? 0
        let seededCount = city.allDistricts.filter { $0.isSeeded }.count
        
        // Saturation: influence everywhere
        if avgInfluence > 0.85 && seededCount == city.allDistricts.count {
            city.gameState = .saturation
            addEvent("Whatever it was… it's everywhere now.", type: .milestone)
            pause()
            return
        }
        
        // Coexistence: stable balance
        if tickCount > 100 && avgInfluence > 0.3 && avgInfluence < 0.6 && avgSuppression > 0.3 {
            let recentChanges = city.allDistricts.map { abs($0.influence - avgInfluence) }.reduce(0, +)
            if recentChanges < 1.0 {
                city.gameState = .coexistence
                addEvent("A strange balance has emerged.", type: .milestone)
                pause()
                return
            }
        }
        
        // Collapse: high stress everywhere
        let avgStress = city.allDistricts.reduce(0.0) { $0 + $1.stress } / Float(city.allDistricts.count)
        if avgStress > 0.8 && avgInfluence > 0.4 {
            city.gameState = .collapse
            addEvent("The city couldn't hold.", type: .milestone)
            pause()
            return
        }
        
        // Eradication: influence eliminated
        if seededCount > 0 && tickCount > 50 {
            let totalInfluence = city.allDistricts.reduce(0.0) { $0 + $1.influence }
            if totalInfluence < 0.1 && avgSuppression > 0.5 {
                city.gameState = .eradication
                addEvent("Whatever it was… it's gone.", type: .milestone)
                pause()
                return
            }
        }
    }
    
    // MARK: - Player Actions
    
    func seedDistrict(_ district: District) {
        guard !district.isSeeded else { return }
        district.isSeeded = true
        district.influence = 0.1
        addEvent("It begins.", type: .spread, districtId: district.id)
    }
    
    func disturbDistrict(_ district: District) {
        guard mutationPoints >= 1 else { return }
        mutationPoints -= 1
        
        district.stress += 0.2
        district.activityLevel *= 1.3
        
        if district.isSeeded {
            district.influence += 0.1
        }
        
        // Spread to neighbors with small chance
        for neighbor in city.getNeighbors(of: district) {
            if Float.random(in: 0...1) < 0.3 {
                neighbor.stress += 0.1
            }
        }
        
        addEvent("Disruption in \(district.activityDescription.lowercased()) area.", type: .observation, districtId: district.id)
    }
    
    func suppressDistrict(_ district: District) {
        guard mutationPoints >= 1 else { return }
        mutationPoints -= 1
        
        district.suppressionLevel = min(1.0, district.suppressionLevel + 0.3)
        district.activityLevel *= 0.5
        
        addEvent("Attention diverted.", type: .observation, districtId: district.id)
    }
    
    func applyMutation(_ mutation: Mutation) {
        guard mutationPoints >= mutation.cost else { return }
        guard !activeMutations.contains(where: { $0.id == mutation.id }) else { return }
        
        mutationPoints -= mutation.cost
        activeMutations.append(mutation)
        
        // Apply volatility immediately
        if case .volatilityIncrease(let increase) = mutation.effect {
            for district in city.allDistricts {
                district.stress += Float.random(in: 0...(increase * 0.3))
            }
        }
        
        addEvent("Something evolved.", type: .milestone)
    }
    
    private func addEvent(_ message: String, type: GameEvent.EventType, districtId: UUID? = nil) {
        let event = GameEvent(message: message, type: type, districtId: districtId)
        events.insert(event, at: 0)
        
        // Keep only recent events
        if events.count > 20 {
            events.removeLast()
        }
    }
}
