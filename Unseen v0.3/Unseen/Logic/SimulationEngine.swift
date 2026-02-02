import Foundation
import Combine

class SimulationEngine: ObservableObject {
    @Published var usa: USA
    @Published var newsEvents: [NewsEvent] = []
    @Published var tickCount: Int = 0
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    let tickInterval: TimeInterval = 1.2
    
    // News generation tracking
    private var lastMilestoneAnnounced: Float = 0
    private var statesReachedThisTick: [String] = []
    private var counterStatesReachedThisTick: [String] = []
    
    init(usa: USA) {
        self.usa = usa
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
        guard usa.gameState == .playing else { return }
        
        tickCount += 1
        usa.gameTime += 1
        
        // Clear tracking for news
        statesReachedThisTick.removeAll()
        counterStatesReachedThisTick.removeAll()
        
        // Core simulation
        spreadIdea()
        spreadCounterIdea()
        processConversions()
        processSocialDynamics()
        
        // Update stats
        usa.updateGlobalStats()
        
        // Generate influence points
        generateInfluencePoints()
        
        // Check for counter-idea emergence
        checkCounterIdeaEmergence()
        
        // Generate news
        generateNews()
        
        // Check win/lose
        checkGameState()
    }
    
    // MARK: - Idea Spread
    
    private func spreadIdea() {
        let infectedStates = usa.allStates.filter { $0.ideaAdopters > 0 }
        
        for state in infectedStates {
            // Internal spread within state
            let internalSpread = calculateInternalSpread(for: state)
            if internalSpread > 0 {
                state.adoptIdea(count: internalSpread)
            }
            
            // Cross-state spread via vectors
            spreadToNeighbors(from: state)
            spreadViaSocialMedia(from: state)
            spreadViaMainstream(from: state)
            spreadViaInstitutions(from: state)
            spreadViaCulture(from: state)
        }
    }
    
    private func calculateInternalSpread(for state: StateRegion) -> Int {
        let baseRate = usa.vectorLevels[.grassroots] ?? 0.1
        var spreadRate = baseRate * (1.0 + usa.spreadBonus)
        
        // State type modifiers
        switch state.stateData.type {
        case .urban: spreadRate *= 1.4
        case .suburban: spreadRate *= 1.0
        case .rural: spreadRate *= 0.6
        case .swing: spreadRate *= 1.2
        }
        
        // Political leaning affects spread (ideas spread faster among sympathetic populations)
        // Negative leaning = liberal, positive = conservative
        // For now, assume the "idea" spreads easier in moderate/liberal areas
        let leaningModifier = 1.0 - (state.stateData.politicalLeaning * 0.2)
        spreadRate *= leaningModifier
        
        // Social unrest slows spread
        spreadRate *= (1.0 - state.socialUnrest * 0.3)
        
        // Calculate actual converts
        let potentialConverts = Float(state.unconvinced) * spreadRate * 0.01
        return Int(potentialConverts * Float.random(in: 0.8...1.2))
    }
    
    private func spreadToNeighbors(from state: StateRegion) {
        let neighbors = usa.getNeighbors(of: state)
        let spreadStrength = (usa.vectorLevels[.grassroots] ?? 0.1) * state.ideaAdoptionRate
        
        for neighbor in neighbors {
            if Float.random(in: 0...1) < spreadStrength * 0.5 {
                let converts = Int(Float(neighbor.unconvinced) * spreadStrength * 0.005 * Float.random(in: 0.5...1.5))
                if converts > 0 {
                    let wasEmpty = neighbor.ideaAdopters == 0
                    neighbor.adoptIdea(count: converts)
                    if wasEmpty && neighbor.ideaAdopters > 0 {
                        statesReachedThisTick.append(neighbor.id)
                    }
                }
            }
        }
    }
    
    private func spreadViaSocialMedia(from state: StateRegion) {
        let level = usa.vectorLevels[.socialMedia] ?? 0
        guard level > 0.05 else { return }
        
        // Social media can jump to any state
        let jumpChance = level * state.ideaAdoptionRate * 0.3
        
        for targetState in usa.allStates {
            if targetState.id == state.id { continue }
            if Float.random(in: 0...1) < jumpChance {
                // Urban and suburban states more affected by social media
                var modifier: Float = 1.0
                switch targetState.stateData.type {
                case .urban: modifier = 1.5
                case .suburban: modifier = 1.2
                case .rural: modifier = 0.5
                case .swing: modifier = 1.3
                }
                
                let converts = Int(Float(targetState.unconvinced) * level * 0.002 * modifier)
                if converts > 0 {
                    let wasEmpty = targetState.ideaAdopters == 0
                    targetState.adoptIdea(count: converts)
                    if wasEmpty && targetState.ideaAdopters > 0 {
                        statesReachedThisTick.append(targetState.id)
                    }
                }
            }
        }
    }
    
    private func spreadViaMainstream(from state: StateRegion) {
        let level = usa.vectorLevels[.mainstream] ?? 0
        guard level > 0.05 else { return }
        
        // Mainstream media affects all states but especially swing states
        let nationalReach = level * usa.globalIdeaAdoption * 0.5
        
        for targetState in usa.allStates {
            var modifier: Float = 1.0
            if targetState.stateData.type == .swing { modifier = 1.4 }
            
            let converts = Int(Float(targetState.unconvinced) * nationalReach * 0.001 * modifier)
            if converts > 0 {
                let wasEmpty = targetState.ideaAdopters == 0
                targetState.adoptIdea(count: converts)
                if wasEmpty && targetState.ideaAdopters > 0 {
                    statesReachedThisTick.append(targetState.id)
                }
            }
        }
        
        // Mainstream coverage increases visibility
        if level > 0.1 {
            usa.counterIdeaStrength += level * 0.002
        }
    }
    
    private func spreadViaInstitutions(from state: StateRegion) {
        let level = usa.vectorLevels[.institutions] ?? 0
        guard level > 0.05 else { return }
        
        // Institutions spread to neighboring states with similar characteristics
        let neighbors = usa.getNeighbors(of: state)
        
        for neighbor in neighbors {
            // Similar political leaning helps institutional spread
            let leaningDiff = abs(state.stateData.politicalLeaning - neighbor.stateData.politicalLeaning)
            let similarity = 1.0 - leaningDiff
            
            let converts = Int(Float(neighbor.unconvinced) * level * 0.003 * similarity)
            if converts > 0 {
                neighbor.adoptIdea(count: converts)
            }
        }
    }
    
    private func spreadViaCulture(from state: StateRegion) {
        let level = usa.vectorLevels[.culture] ?? 0
        guard level > 0.05 else { return }
        
        // Culture spreads slowly but creates lasting adoption
        for targetState in usa.allStates {
            let converts = Int(Float(targetState.unconvinced) * level * 0.001)
            if converts > 0 {
                targetState.adoptIdea(count: converts)
            }
        }
    }
    
    // MARK: - Counter-Idea Spread
    
    private func spreadCounterIdea() {
        guard usa.counterIdeaActive else { return }
        
        let counterStrength = usa.counterIdeaStrength * usa.difficulty.counterSpeedMultiplier
        
        for state in usa.allStates {
            // Counter spreads faster in areas with existing counter presence
            var localStrength = counterStrength
            if state.counterAdopters > 0 {
                localStrength *= (1.0 + state.counterAdoptionRate)
            }
            
            // Echo chambers protect from counter
            if state.echoChambered {
                localStrength *= (1.0 - usa.echoStrength)
            }
            
            // Political leaning affects counter spread
            // Conservative areas more receptive to counter-idea
            localStrength *= (1.0 + state.stateData.politicalLeaning * 0.3)
            
            let converts = Int(Float(state.unconvinced) * localStrength * 0.01)
            if converts > 0 {
                let wasEmpty = state.counterAdopters == 0
                state.adoptCounter(count: converts)
                if wasEmpty && state.counterAdopters > 0 {
                    counterStatesReachedThisTick.append(state.id)
                }
            }
        }
        
        // Counter can also spread from state to state
        let counterStates = usa.allStates.filter { $0.counterAdopters > $0.totalPopulation / 10 }
        for state in counterStates {
            let neighbors = usa.getNeighbors(of: state)
            for neighbor in neighbors {
                if neighbor.echoChambered { continue }
                
                let converts = Int(Float(neighbor.unconvinced) * state.counterAdoptionRate * counterStrength * 0.005)
                if converts > 0 {
                    neighbor.adoptCounter(count: converts)
                }
            }
        }
    }
    
    // MARK: - Conversions
    
    private func processConversions() {
        for state in usa.allStates {
            // Strong majorities can convert the other side
            if state.ideaAdoptionRate > 0.6 && state.counterAdopters > 0 {
                let convertPower = (state.ideaAdoptionRate - 0.5) * 0.05 * (1.0 + usa.culturalResilience)
                let converts = Int(Float(state.counterAdopters) * convertPower)
                if converts > 0 {
                    state.convertToIdea(count: converts)
                }
            }
            
            if state.counterAdoptionRate > 0.6 && state.ideaAdopters > 0 {
                var convertPower = (state.counterAdoptionRate - 0.5) * 0.05
                if state.echoChambered {
                    convertPower *= (1.0 - usa.echoStrength)
                }
                convertPower *= (1.0 - usa.culturalResilience * 0.5)
                let converts = Int(Float(state.ideaAdopters) * convertPower)
                if converts > 0 {
                    state.convertToCounter(count: converts)
                }
            }
        }
    }
    
    // MARK: - Social Dynamics
    
    private func processSocialDynamics() {
        for state in usa.allStates {
            // Contested states develop social unrest
            if state.ideaAdoptionRate > 0.25 && state.counterAdoptionRate > 0.25 {
                let contestLevel = min(state.ideaAdoptionRate, state.counterAdoptionRate)
                state.socialUnrest = min(1.0, state.socialUnrest + contestLevel * 0.02)
            } else {
                state.socialUnrest = max(0, state.socialUnrest - 0.01)
            }
            
            // High unrest causes disengagement
            if state.socialUnrest > 0.6 {
                let disengageCount = Int(Float(state.ideaAdopters + state.counterAdopters) * state.socialUnrest * 0.01)
                if disengageCount > 0 {
                    state.disengage(count: disengageCount)
                }
            }
            
            // Media attention based on activity
            state.mediaAttention = state.ideaAdoptionRate * 0.5 + state.socialUnrest * 0.3
            if state.stateData.type == .swing {
                state.mediaAttention *= 1.5
            }
        }
    }
    
    // MARK: - Influence Points
    
    private func generateInfluencePoints() {
        // Base generation from adoption
        let adoptionBonus = Int(usa.globalIdeaAdoption * 3)
        
        // Bonus from new converts this tick
        let newConverts = usa.allStates.reduce(0) { total, state in
            total + (state.ideaAdopters > state.totalPopulation / 100 ? 1 : 0)
        }
        let convertBonus = newConverts > 30 ? 1 : 0
        
        // Cultural resilience generates passive income
        let cultureBonus = Int(usa.culturalResilience * 2)
        
        // Random events
        let eventBonus = tickCount % 20 == 0 ? Int.random(in: 1...3) : 0
        
        usa.influencePoints += max(1, adoptionBonus + convertBonus + cultureBonus + eventBonus)
    }
    
    // MARK: - Counter-Idea Emergence
    
    private func checkCounterIdeaEmergence() {
        guard !usa.counterIdeaActive else { return }
        
        // Calculate visibility from all vectors
        var visibility: Float = 0
        for (vector, level) in usa.vectorLevels {
            visibility += level * vector.visibilityImpact
        }
        visibility += usa.globalIdeaAdoption * 0.3
        
        // Counter emerges at visibility threshold
        if visibility > 0.15 || usa.globalIdeaAdoption > 0.20 {
            usa.counterIdeaActive = true
            usa.counterIdeaStrength = 0.05 + visibility * 0.1
            
            // Seed counter in resistant states
            for state in usa.allStates {
                if state.stateData.politicalLeaning > 0.3 && state.ideaAdoptionRate < 0.3 {
                    let seedAmount = Int(Float(state.unconvinced) * 0.05)
                    state.adoptCounter(count: seedAmount)
                }
            }
            
            addNews(
                headline: "Growing concerns about new cultural movement",
                source: newsSources.randomElement()!,
                type: .counter,
                stateId: nil
            )
        }
    }
    
    // MARK: - Game State Check
    
    private func checkGameState() {
        // Win: Idea reaches threshold
        if usa.globalIdeaAdoption >= usa.difficulty.winThreshold &&
           usa.globalCounterAdoption < usa.difficulty.counterLoseThreshold {
            usa.gameState = .ideaWins
            addNews(
                headline: "Historic shift: America transformed",
                source: "Associated Press",
                type: .milestone,
                stateId: nil
            )
            pause()
            return
        }
        
        // Lose: Counter dominates
        if usa.globalCounterAdoption > usa.difficulty.winThreshold {
            usa.gameState = .counterWins
            addNews(
                headline: "Backlash complete: Movement rejected nationwide",
                source: "Reuters",
                type: .counter,
                stateId: nil
            )
            pause()
            return
        }
        
        // Coexistence: Stable balance
        if tickCount > 150 &&
           usa.globalIdeaAdoption > 0.35 && usa.globalIdeaAdoption < 0.65 &&
           usa.globalCounterAdoption > 0.20 && usa.globalCounterAdoption < 0.45 {
            let totalChange = usa.allStates.reduce(Float(0)) { $0 + $1.socialUnrest }
            if totalChange < 5.0 {
                usa.gameState = .coexistence
                addNews(
                    headline: "A divided nation finds uneasy equilibrium",
                    source: "NPR",
                    type: .milestone,
                    stateId: nil
                )
                pause()
                return
            }
        }
        
        // Collapse: Too many disengaged
        if usa.globalDisengaged > 0.35 {
            usa.gameState = .collapse
            addNews(
                headline: "Trust in institutions hits historic low",
                source: "Pew Research",
                type: .warning,
                stateId: nil
            )
            pause()
            return
        }
    }
    
    // MARK: - News Generation
    
    private func generateNews() {
        // New states reached
        for stateId in statesReachedThisTick {
            if let state = usa.getState(stateId) {
                let headlines = [
                    "Reports emerge from \(state.stateData.name)",
                    "\(state.stateData.name) sees first signs of movement",
                    "Unusual activity reported in \(state.stateData.name)",
                    "\(state.stateData.name) residents discuss new ideas"
                ]
                addNews(
                    headline: headlines.randomElement()!,
                    source: "Local News",
                    type: .spread,
                    stateId: stateId
                )
            }
        }
        
        // Counter reaches new states
        for stateId in counterStatesReachedThisTick {
            if let state = usa.getState(stateId) {
                let headlines = [
                    "Pushback organizing in \(state.stateData.name)",
                    "\(state.stateData.name) groups voice opposition",
                    "Counter-movement gains ground in \(state.stateData.name)"
                ]
                addNews(
                    headline: headlines.randomElement()!,
                    source: newsSources.randomElement()!,
                    type: .counter,
                    stateId: stateId
                )
            }
        }
        
        // Milestone announcements
        let milestones: [(Float, String)] = [
            (0.10, "Movement reaches 10% of Americans"),
            (0.25, "Quarter of nation now engaged"),
            (0.40, "Movement hits critical mass"),
            (0.50, "Half of America transformed"),
            (0.60, "Tipping point reached: 60% adoption"),
            (0.75, "Three quarters of nation on board"),
            (0.90, "Near-total cultural shift underway")
        ]
        
        for (threshold, headline) in milestones {
            if usa.globalIdeaAdoption >= threshold && lastMilestoneAnnounced < threshold {
                lastMilestoneAnnounced = threshold
                addNews(
                    headline: headline,
                    source: newsSources.randomElement()!,
                    type: .milestone,
                    stateId: nil
                )
                break
            }
        }
        
        // Random flavor news
        if tickCount % 8 == 0 {
            generateFlavorNews()
        }
        
        // High unrest warnings
        let unrestedStates = usa.allStates.filter { $0.socialUnrest > 0.6 }
        if !unrestedStates.isEmpty && tickCount % 12 == 0 {
            if let state = unrestedStates.randomElement() {
                let headlines = [
                    "Tensions boil over in \(state.stateData.name)",
                    "Protests reported across \(state.stateData.name)",
                    "\(state.stateData.name) sees heated confrontations"
                ]
                addNews(
                    headline: headlines.randomElement()!,
                    source: "Local News",
                    type: .warning,
                    stateId: state.id
                )
            }
        }
    }
    
    private func generateFlavorNews() {
        let adoption = usa.globalIdeaAdoption
        
        if adoption < 0.15 {
            let headlines = [
                "Social media buzzing about mysterious trend",
                "\"Something's different\" - early adopters share experiences",
                "Small gatherings pop up in scattered communities",
                "Online forums see surge in unusual discussions"
            ]
            addNews(headline: headlines.randomElement()!, source: "Social Media", type: .spread, stateId: nil)
        } else if adoption < 0.35 {
            let headlines = [
                "Local businesses report changing customer behavior",
                "Schools see shift in student attitudes",
                "Churches address congregation's new interests",
                "Workplaces adapt to emerging cultural shift",
                "Study finds generational divide on key issue"
            ]
            addNews(headline: headlines.randomElement()!, source: newsSources.randomElement()!, type: .cultural, stateId: nil)
        } else if adoption < 0.60 {
            let headlines = [
                "Politicians weigh in on national conversation",
                "Corporate America responds to cultural shift",
                "Universities revise curricula amid changes",
                "Media coverage intensifies on both sides",
                "Celebrity endorsements fuel debate"
            ]
            addNews(headline: headlines.randomElement()!, source: newsSources.randomElement()!, type: .political, stateId: nil)
        } else {
            let headlines = [
                "Holdout communities feel increasing pressure",
                "Last bastions of resistance mobilize",
                "Cultural transformation nears completion",
                "Historians weigh in on unprecedented shift"
            ]
            addNews(headline: headlines.randomElement()!, source: newsSources.randomElement()!, type: .milestone, stateId: nil)
        }
    }
    
    private func addNews(headline: String, source: String, type: NewsEvent.EventType, stateId: String?) {
        let event = NewsEvent(
            headline: headline,
            source: source,
            type: type,
            stateId: stateId,
            timestamp: usa.gameTime
        )
        newsEvents.insert(event, at: 0)
        
        // Keep only recent news
        if newsEvents.count > 50 {
            newsEvents.removeLast()
        }
    }
    
    // MARK: - Player Actions
    
    func seedState(_ state: StateRegion) {
        guard state.ideaAdopters == 0 else { return }
        
        let seedAmount = Int(Float(state.totalPopulation) * 0.01)
        state.adoptIdea(count: seedAmount)
        
        addNews(
            headline: "Something new begins in \(state.stateData.name)",
            source: "Social Media",
            type: .spread,
            stateId: state.id
        )
    }
    
    func amplify(_ state: StateRegion) {
        guard usa.influencePoints >= 2 else { return }
        guard state.ideaAdopters > 0 else { return }
        
        usa.influencePoints -= 2
        
        // Boost spread in this state
        let boostAmount = Int(Float(state.unconvinced) * 0.05)
        state.adoptIdea(count: boostAmount)
        
        // Increase media attention
        state.mediaAttention = min(1.0, state.mediaAttention + 0.2)
        
        let headlines = [
            "Viral moment in \(state.stateData.name) sparks conversation",
            "\(state.stateData.name) event goes viral",
            "Social media explodes over \(state.stateData.name) happenings"
        ]
        addNews(
            headline: headlines.randomElement()!,
            source: "Social Media",
            type: .spread,
            stateId: state.id
        )
    }
    
    func createEchoChamber(_ state: StateRegion) {
        guard usa.influencePoints >= 3 else { return }
        guard state.ideaAdopters > state.totalPopulation / 10 else { return }
        guard !state.echoChambered else { return }
        
        usa.influencePoints -= 3
        state.echoChambered = true
        
        addNews(
            headline: "\(state.stateData.name) communities strengthen their networks",
            source: "Local News",
            type: .cultural,
            stateId: state.id
        )
    }
    
    func purchaseUpgrade(_ upgrade: Upgrade) {
        guard usa.influencePoints >= upgrade.cost else { return }
        guard !usa.purchasedUpgrades.contains(upgrade.name) else { return }
        guard upgrade.prerequisites.allSatisfy({ usa.purchasedUpgrades.contains($0) }) else { return }
        
        usa.influencePoints -= upgrade.cost
        usa.purchasedUpgrades.insert(upgrade.name)
        
        // Apply effects
        for effect in upgrade.effects {
            switch effect {
            case .vectorBoost(let vector, let amount):
                usa.vectorLevels[vector] = (usa.vectorLevels[vector] ?? 0) + amount
            case .spreadBonus(let amount):
                usa.spreadBonus += amount
            case .echoStrength(let amount):
                usa.echoStrength += amount
            case .culturalResilience(let amount):
                usa.culturalResilience += amount
            case .reduceVisibility(let amount):
                usa.counterIdeaStrength = max(0, usa.counterIdeaStrength - amount * 0.1)
            case .convertPower(let amount):
                usa.culturalResilience += amount * 0.5
            case .stabilize(let amount):
                for state in usa.allStates {
                    state.socialUnrest = max(0, state.socialUnrest - amount)
                }
            }
        }
        
        addNews(
            headline: "Movement evolves: \(upgrade.name)",
            source: "Viral Post",
            type: .milestone,
            stateId: nil
        )
    }
}
