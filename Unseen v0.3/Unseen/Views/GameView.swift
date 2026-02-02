import SwiftUI
import SceneKit

struct GameView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @StateObject private var mapController = USAMapController()
    @State private var showOpeningLine = true
    @State private var openingLineOpacity: Double = 0
    
    var body: some View {
        ZStack {
            CitySceneView(mapController: mapController) { state in
                if let state = state {
                    viewModel.selectState(state)
                    mapController.highlightState(state)
                } else {
                    viewModel.deselectState()
                    mapController.highlightState(nil)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TopHUD()
                
                Spacer()
                
                // Counter-idea bar
                if let usa = viewModel.usa, usa.counterIdeaActive {
                    CounterIdeaBar(strength: usa.counterIdeaStrength, adoption: usa.globalCounterAdoption)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                GlobalStatsBar()
                    .padding(.bottom, 4)
                
                // News ticker
                NewsTicker()
                    .padding(.bottom, 8)
                
                if viewModel.selectedState != nil {
                    StatePanel()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                ActionBar()
            }
            
            if showOpeningLine {
                OpeningLineOverlay(
                    scenario: viewModel.selectedScenario ?? .random,
                    opacity: openingLineOpacity
                )
            }
            
            if viewModel.showUpgrades {
                UpgradePanel()
                    .transition(.opacity)
            }
            
            if viewModel.showPauseMenu {
                PauseMenuOverlay()
                    .transition(.opacity)
            }
            
            if viewModel.showEndScreen {
                EndGameOverlay()
                    .transition(.opacity)
            }
        }
        .onAppear { setupGame() }
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedState != nil)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showUpgrades)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showPauseMenu)
        .animation(.easeInOut(duration: 0.3), value: viewModel.usa?.counterIdeaActive)
    }
    
    private func setupGame() {
        guard let usa = viewModel.usa else { return }
        mapController.generateMap(from: usa)
        
        withAnimation(.easeIn(duration: 1.5).delay(0.5)) { openingLineOpacity = 1 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeOut(duration: 1.0)) { openingLineOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showOpeningLine = false }
        }
        
        // Update visuals periodically
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            mapController.updateStateVisuals()
        }
    }
}

// MARK: - News Ticker

struct NewsTicker: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array((viewModel.simulation?.newsEvents.prefix(3) ?? []).enumerated()), id: \.element.id) { index, event in
                HStack(spacing: 8) {
                    Image(systemName: iconForEventType(event.type))
                        .font(.system(size: 9))
                        .foregroundColor(colorForEventType(event.type))
                    
                    Text(event.headline)
                        .font(.system(size: 11, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(1.0 - Double(index) * 0.25))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(event.source)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
        )
        .padding(.horizontal, 16)
        .animation(.easeOut(duration: 0.3), value: viewModel.simulation?.newsEvents.first?.id)
    }
    
    private func iconForEventType(_ type: NewsEvent.EventType) -> String {
        switch type {
        case .spread: return "arrow.up.right"
        case .counter: return "arrow.uturn.backward"
        case .milestone: return "star.fill"
        case .backlash: return "exclamationmark.triangle"
        case .cultural: return "theatermasks"
        case .political: return "building.columns"
        case .warning: return "flame"
        }
    }
    
    private func colorForEventType(_ type: NewsEvent.EventType) -> Color {
        switch type {
        case .spread: return Color(red: 0.4, green: 0.75, blue: 0.55)
        case .counter: return Color(red: 0.75, green: 0.45, blue: 0.5)
        case .milestone: return Color(red: 0.6, green: 0.5, blue: 0.8)
        case .backlash: return Color(red: 0.9, green: 0.6, blue: 0.4)
        case .cultural: return Color(red: 0.6, green: 0.6, blue: 0.8)
        case .political: return Color(red: 0.5, green: 0.6, blue: 0.7)
        case .warning: return Color(red: 1.0, green: 0.5, blue: 0.4)
        }
    }
}

// MARK: - Counter-Idea Bar

struct CounterIdeaBar: View {
    let strength: Float
    let adoption: Float
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 0.75, green: 0.45, blue: 0.5))
                
                Text("BACKLASH")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(2)
                    .foregroundColor(Color(red: 0.75, green: 0.45, blue: 0.5))
                
                Spacer()
                
                Text("\(Int(adoption * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 0.75, green: 0.45, blue: 0.5))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.75, green: 0.45, blue: 0.5).opacity(0.7))
                        .frame(width: geo.size.width * CGFloat(adoption))
                }
            }
            .frame(height: 4)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.75, green: 0.45, blue: 0.5).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Pause Menu Overlay

struct PauseMenuOverlay: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("PAUSED")
                    .font(.system(size: 24, weight: .thin))
                    .tracking(8)
                    .foregroundColor(.white)
                
                if let usa = viewModel.usa {
                    VStack(spacing: 8) {
                        Divider().background(Color.white.opacity(0.2))
                        
                        Text("PROGRESS")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.5))
                        
                        HStack(spacing: 20) {
                            VStack(spacing: 2) {
                                Text("\(Int(usa.globalIdeaAdoption * 100))%")
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.55))
                                Text("Adoption")
                                    .font(.system(size: 9, weight: .light))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            VStack(spacing: 2) {
                                Text("\(Int(usa.globalCounterAdoption * 100))%")
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color(red: 0.7, green: 0.45, blue: 0.5))
                                Text("Backlash")
                                    .font(.system(size: 9, weight: .light))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            VStack(spacing: 2) {
                                Text("\(Int(usa.difficulty.winThreshold * 100))%")
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8))
                                Text("Goal")
                                    .font(.system(size: 9, weight: .light))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                    }
                    .padding(.vertical, 8)
                }
                
                VStack(spacing: 12) {
                    PauseMenuButton(title: "RESUME", icon: "play.fill") {
                        viewModel.resumeGame()
                    }
                    
                    PauseMenuButton(title: "SAVE & QUIT", icon: "square.and.arrow.down") {
                        viewModel.saveAndQuit()
                    }
                    
                    PauseMenuButton(title: "RESTART", icon: "arrow.counterclockwise", isDestructive: true) {
                        viewModel.restartGame()
                    }
                }
                .padding(.top, 8)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.1).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
        }
    }
}

struct PauseMenuButton: View {
    let title: String
    let icon: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .tracking(2)
            }
            .foregroundColor(isDestructive ? Color(red: 1.0, green: 0.5, blue: 0.4) : .white)
            .frame(width: 180, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isDestructive ? Color(red: 1.0, green: 0.5, blue: 0.4).opacity(0.3) : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Global Stats Bar

struct GlobalStatsBar: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        if let usa = viewModel.usa {
            HStack(spacing: 12) {
                StatPill(
                    icon: "brain.head.profile",
                    label: "Adoption",
                    value: "\(Int(usa.globalIdeaAdoption * 100))%",
                    color: Color(red: 0.4, green: 0.7, blue: 0.55)
                )
                
                let reachedStates = usa.allStates.filter { $0.ideaAdopters > 0 }.count
                StatPill(
                    icon: "map.fill",
                    label: "States",
                    value: "\(reachedStates)/51",
                    color: Color(red: 0.6, green: 0.5, blue: 0.8)
                )
                
                StatPill(
                    icon: "person.fill.questionmark",
                    label: "Undecided",
                    value: "\(Int((1 - usa.globalIdeaAdoption - usa.globalCounterAdoption - usa.globalDisengaged) * 100))%",
                    color: Color(red: 0.6, green: 0.6, blue: 0.65)
                )
            }
            .padding(.horizontal, 16)
        }
    }
}

struct StatPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label.uppercased())
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                Text(value)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Opening Line Overlay

struct OpeningLineOverlay: View {
    let scenario: GameViewModel.GameScenario
    let opacity: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.75 * opacity)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: scenario.icon)
                    .font(.system(size: 40, weight: .thin))
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8))
                
                Text(scenario.rawValue.uppercased())
                    .font(.system(size: 24, weight: .thin))
                    .tracking(8)
                    .foregroundColor(.white)
                
                Text("An idea begins to spread...")
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundColor(.white.opacity(0.7))
                    .italic()
            }
            .opacity(opacity)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Top HUD

struct TopHUD: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var currentPoints: Int {
        viewModel.usa?.influencePoints ?? 0
    }
    
    var body: some View {
        HStack {
            Button(action: { viewModel.togglePause() }) {
                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let usa = viewModel.usa {
                    Text("DAY \(usa.gameTime)")
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                if !viewModel.showUpgrades {
                    HStack(spacing: 6) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8))
                        Text("\(currentPoints)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            Button(action: { viewModel.returnToDifficultySelect() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - State Panel

struct StatePanel: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        if let state = viewModel.selectedState {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.stateData.name.uppercased())
                            .font(.system(size: 14, weight: .medium))
                            .tracking(2)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Text(stateTypeLabel(state.stateData.type))
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("•")
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("\(formatPopulation(state.stateData.population))")
                                .font(.system(size: 10, weight: .light, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                    
                    if state.echoChambered {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat.circle.fill")
                                .font(.system(size: 10))
                            Text("ECHO")
                                .font(.system(size: 8, weight: .medium))
                                .tracking(1)
                        }
                        .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.7))
                    }
                    
                    Button(action: { viewModel.deselectState() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                // Status message
                Text(state.statusMessage)
                    .font(.system(size: 12, weight: .light, design: .serif))
                    .foregroundColor(.white.opacity(0.7))
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Population bars
                HStack(spacing: 16) {
                    PopulationBar(
                        label: "Adopted",
                        value: state.ideaAdoptionRate,
                        color: Color(red: 0.4, green: 0.7, blue: 0.55)
                    )
                    
                    PopulationBar(
                        label: "Counter",
                        value: state.counterAdoptionRate,
                        color: Color(red: 0.7, green: 0.45, blue: 0.5)
                    )
                    
                    PopulationBar(
                        label: "Open",
                        value: state.contestedRate,
                        color: Color(red: 0.6, green: 0.6, blue: 0.65)
                    )
                }
                
                // Unrest warning
                if state.socialUnrest > 0.3 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text("Social tension: \(Int(state.socialUnrest * 100))%")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.4))
                }
                
                // Actions
                HStack(spacing: 12) {
                    if !viewModel.hasSeeded {
                        GameActionButton(title: "SEED", icon: "target", enabled: viewModel.canSeed, style: .primary) {
                            viewModel.seedSelectedState()
                        }
                    } else if state.ideaAdopters > 0 {
                        GameActionButton(title: "AMPLIFY", icon: "speaker.wave.2.fill", enabled: viewModel.canAmplify, style: .primary) {
                            viewModel.amplifySelectedState()
                        }
                        
                        if !state.echoChambered {
                            GameActionButton(title: "ECHO", icon: "repeat.circle", enabled: viewModel.canCreateEchoChamber, style: .subtle) {
                                viewModel.createEchoChamber()
                            }
                        }
                    } else {
                        Text("The idea hasn't reached here yet")
                            .font(.system(size: 11, weight: .light, design: .serif))
                            .foregroundColor(.white.opacity(0.4))
                            .italic()
                    }
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
        }
    }
    
    private func stateTypeLabel(_ type: USState.StateType) -> String {
        switch type {
        case .urban: return "Urban"
        case .suburban: return "Suburban"
        case .rural: return "Rural"
        case .swing: return "Swing State"
        }
    }
    
    private func formatPopulation(_ pop: Int) -> String {
        if pop >= 1000000 {
            return String(format: "%.1fM", Float(pop) / 1000000)
        } else {
            return String(format: "%.0fK", Float(pop) / 1000)
        }
    }
}

struct PopulationBar: View {
    let label: String
    let value: Float
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(value * 100))%")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(color)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.7))
                        .frame(width: geo.size.width * CGFloat(value))
                }
            }
            .frame(height: 4)
            
            Text(label)
                .font(.system(size: 8, weight: .light))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Game Action Button

struct GameActionButton: View {
    let title: String
    let icon: String
    let enabled: Bool
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, warning, subtle
        
        var activeColor: Color {
            switch self {
            case .primary: return Color(red: 0.4, green: 0.7, blue: 0.55)
            case .warning: return Color(red: 0.9, green: 0.6, blue: 0.3)
            case .subtle: return Color(red: 0.6, green: 0.5, blue: 0.8)
            }
        }
    }
    
    @State private var showFeedback = false
    
    var body: some View {
        Button(action: {
            guard enabled else { return }
            
            withAnimation(.easeOut(duration: 0.1)) { showFeedback = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeIn(duration: 0.2)) { showFeedback = false }
            }
            
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
            }
            .foregroundColor(enabled ? (showFeedback ? .black : .white) : .white.opacity(0.3))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(showFeedback ? style.activeColor : Color.white.opacity(enabled ? 0.1 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(enabled ? style.activeColor.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .disabled(!enabled)
    }
}

// MARK: - Action Bar

struct ActionBar: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: {
                withAnimation { viewModel.showUpgrades.toggle() }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 20, weight: .light))
                    Text("EVOLVE")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1)
                }
                .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Active vectors
            if let usa = viewModel.usa {
                HStack(spacing: 6) {
                    ForEach(InfluenceVector.allCases.filter { (usa.vectorLevels[$0] ?? 0) > 0.05 }) { vector in
                        Image(systemName: vector.icon)
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.7))
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.7))
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Upgrade Panel

struct UpgradePanel: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State private var selectedCategory: UpgradeCategory = .vectors
    
    var currentBalance: Int {
        viewModel.usa?.influencePoints ?? 0
    }
    
    var filteredUpgrades: [Upgrade] {
        viewModel.availableUpgrades.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { viewModel.showUpgrades = false }
                }
            
            VStack(spacing: 16) {
                HStack {
                    Text("EVOLVE")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(4)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8))
                        Text("\(currentBalance)")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                
                // Category tabs
                HStack(spacing: 8) {
                    ForEach(UpgradeCategory.allCases, id: \.self) { category in
                        CategoryTab(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                
                // Active upgrades
                if let usa = viewModel.usa, !usa.purchasedUpgrades.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .medium))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.4))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(allUpgrades.filter { usa.purchasedUpgrades.contains($0.name) }) { upgrade in
                                    HStack(spacing: 4) {
                                        Image(systemName: upgrade.icon)
                                            .font(.system(size: 9))
                                        Text(upgrade.name)
                                            .font(.system(size: 9, weight: .medium))
                                    }
                                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.15))
                                    )
                                }
                            }
                        }
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                }
                
                // Available upgrades
                ScrollView {
                    VStack(spacing: 10) {
                        if filteredUpgrades.isEmpty {
                            Text("All \(selectedCategory.rawValue.lowercased()) upgrades purchased!")
                                .font(.system(size: 12, weight: .light, design: .serif))
                                .foregroundColor(.white.opacity(0.5))
                                .italic()
                                .padding(.vertical, 20)
                        } else {
                            ForEach(filteredUpgrades) { upgrade in
                                UpgradeCard(upgrade: upgrade, currentBalance: currentBalance) {
                                    viewModel.purchaseUpgrade(upgrade)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                
                Button(action: {
                    withAnimation { viewModel.showUpgrades = false }
                }) {
                    Text("CLOSE")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
}

struct CategoryTab: View {
    let category: UpgradeCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue.uppercased())
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.3) : Color.white.opacity(0.05))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UpgradeCard: View {
    let upgrade: Upgrade
    let currentBalance: Int
    let action: () -> Void
    
    @EnvironmentObject var viewModel: GameViewModel
    
    var canAfford: Bool { currentBalance >= upgrade.cost }
    
    var meetsPrerequisites: Bool {
        guard let usa = viewModel.usa else { return false }
        return upgrade.prerequisites.allSatisfy { usa.purchasedUpgrades.contains($0) }
    }
    
    var isAvailable: Bool { canAfford && meetsPrerequisites }
    
    var body: some View {
        Button(action: {
            guard isAvailable else { return }
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            action()
        }) {
            HStack {
                Image(systemName: upgrade.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isAvailable ? Color(red: 0.6, green: 0.5, blue: 0.8) : .white.opacity(0.3))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(upgrade.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isAvailable ? .white : .white.opacity(0.4))
                    
                    Text(upgrade.description)
                        .font(.system(size: 10, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.5))
                        .italic()
                    
                    if !meetsPrerequisites {
                        Text("Requires: \(upgrade.prerequisites.joined(separator: ", "))")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.4).opacity(0.7))
                    }
                }
                
                Spacer()
                
                HStack(spacing: 3) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 8))
                    Text("\(upgrade.cost)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .foregroundColor(canAfford ? Color(red: 0.6, green: 0.5, blue: 0.8) : .white.opacity(0.3))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(isAvailable ? 0.05 : 0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isAvailable ? Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .disabled(!isAvailable)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - End Game Overlay

struct EndGameOverlay: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Text(viewModel.endGameTitle.uppercased())
                        .font(.system(size: 24, weight: .thin))
                        .tracking(8)
                        .foregroundColor(.white)
                    
                    Text(viewModel.endGameMessage)
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.6))
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                if let usa = viewModel.usa {
                    VStack(spacing: 16) {
                        HStack(spacing: 24) {
                            FinalStat(label: "Adoption", value: "\(Int(usa.globalIdeaAdoption * 100))%", color: Color(red: 0.4, green: 0.7, blue: 0.55))
                            FinalStat(label: "Backlash", value: "\(Int(usa.globalCounterAdoption * 100))%", color: Color(red: 0.7, green: 0.45, blue: 0.5))
                            FinalStat(label: "Days", value: "\(usa.gameTime)", color: .white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("SCORE")
                                .font(.system(size: 10, weight: .medium))
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.4))
                            Text("\(viewModel.currentScore)")
                                .font(.system(size: 40, weight: .thin, design: .monospaced))
                                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8))
                        }
                    }
                }
                
                VStack(spacing: 12) {
                    MenuButton(title: "TRY AGAIN") {
                        viewModel.restartGame()
                    }
                    
                    MenuButton(title: "NEW SCENARIO") {
                        viewModel.returnToDifficultySelect()
                    }
                }
            }
        }
    }
}

struct FinalStat: View {
    let label: String
    let value: String
    var color: Color = .white
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(color)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .light))
                .tracking(1)
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
