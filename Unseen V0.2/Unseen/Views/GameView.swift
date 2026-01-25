import SwiftUI
import SceneKit

struct GameView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @StateObject private var sceneController = CitySceneController()
    @State private var showOpeningLine = true
    @State private var openingLineOpacity: Double = 0
    
    var body: some View {
        ZStack {
            CitySceneView(sceneController: sceneController) { district in
                if let district = district {
                    viewModel.selectDistrict(district)
                    sceneController.highlightDistrict(district)
                } else {
                    viewModel.deselectDistrict()
                    sceneController.highlightDistrict(nil)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TopHUD()
                
                Spacer()
                
                GlobalStatsBar()
                    .padding(.bottom, 4)
                
                EventFeed()
                    .padding(.bottom, 8)
                
                if viewModel.selectedDistrict != nil {
                    DistrictPanel()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                ActionBar()
            }
            
            if showOpeningLine {
                OpeningLineOverlay(
                    scenario: viewModel.selectedScenario ?? .unknown,
                    opacity: openingLineOpacity
                )
            }
            
            if viewModel.showMutations {
                MutationPanel()
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
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedDistrict != nil)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showMutations)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showPauseMenu)
    }
    
    private func setupGame() {
        guard let city = viewModel.city else { return }
        sceneController.generateCity(from: city)
        
        withAnimation(.easeIn(duration: 1.5).delay(0.5)) { openingLineOpacity = 1 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 1.0)) { openingLineOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showOpeningLine = false }
        }
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
                    .font(.system(size: 24, weight: .thin, design: .default))
                    .tracking(8)
                    .foregroundColor(.white)
                
                // Seed Info Section
                if let seedInfo = viewModel.seedInfo {
                    VStack(spacing: 8) {
                        Divider().background(Color.white.opacity(0.2))
                        
                        Text("SEED STATUS")
                            .font(.system(size: 10, weight: .medium, design: .default))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.5))
                        
                        if let city = viewModel.city {
                            if city.hasBeenSeeded {
                                HStack(spacing: 16) {
                                    VStack(spacing: 2) {
                                        Text("\(Int(seedInfo.influence * 100))%")
                                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                                            .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.8))
                                        Text("Influence")
                                            .font(.system(size: 9, weight: .light))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    
                                    VStack(spacing: 2) {
                                        Text("\(seedInfo.seededCount)/\(seedInfo.totalCount)")
                                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                                            .foregroundColor(Color(red: 0.5, green: 0.7, blue: 0.5))
                                        Text("Reach")
                                            .font(.system(size: 9, weight: .light))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                            } else {
                                Text("Not yet seeded")
                                    .font(.system(size: 12, weight: .light, design: .serif))
                                    .foregroundColor(.white.opacity(0.5))
                                    .italic()
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                    }
                    .padding(.vertical, 8)
                }
                
                // City Seed
                if let seed = viewModel.city?.citySeed {
                    Text("City Seed: \(String(seed, radix: 16).uppercased().prefix(8))")
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
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
    
    @State private var isPressed = false
    
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
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .tracking(2)
            }
            .foregroundColor(isDestructive ? Color(red: 1.0, green: 0.5, blue: 0.4) : .white)
            .frame(width: 180, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(isPressed ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isDestructive ? Color(red: 1.0, green: 0.5, blue: 0.4).opacity(0.3) : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.easeOut(duration: 0.1)) { isPressed = true }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeIn(duration: 0.1)) { isPressed = false }
                }
        )
    }
}

// MARK: - Global Stats Bar

struct GlobalStatsBar: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        if let city = viewModel.city {
            HStack(spacing: 16) {
                StatPill(
                    icon: "waveform.path",
                    label: "Spread",
                    value: "\(Int(city.globalInfluence * 100))%",
                    color: Color(red: 0.7, green: 0.5, blue: 0.8)
                )
                
                StatPill(
                    icon: "shield.fill",
                    label: "Control",
                    value: "\(Int(city.globalSuppression * 100))%",
                    color: Color(red: 0.8, green: 0.5, blue: 0.4)
                )
                
                let seededCount = city.allDistricts.filter { $0.isSeeded }.count
                StatPill(
                    icon: "circle.hexagongrid.fill",
                    label: "Reach",
                    value: "\(seededCount)/\(city.allDistricts.count)",
                    color: Color(red: 0.5, green: 0.7, blue: 0.5)
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
                    .font(.system(size: 7, weight: .medium, design: .default))
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
    let scenario: CityScenario
    let opacity: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7 * opacity)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                if scenario != .unknown {
                    Text(scenario.rawValue.uppercased())
                        .font(.system(size: 24, weight: .thin, design: .default))
                        .tracking(8)
                        .foregroundColor(.white)
                }
                
                if !scenario.openingLine.isEmpty {
                    Text(scenario.openingLine)
                        .font(.system(size: 16, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.7))
                        .italic()
                }
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
        viewModel.simulation?.mutationPoints ?? 0
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
                HStack(spacing: 6) {
                    Circle()
                        .fill(dayPhaseColor)
                        .frame(width: 8, height: 8)
                    Text(dayPhaseText)
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Hide points when mutation panel is shown
                if !viewModel.showMutations {
                    HStack(spacing: 6) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8))
                        Text("\(currentPoints)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                            .id("topHUD_points_\(currentPoints)")
                    }
                }
            }
            
            Button(action: { viewModel.returnToCitySelect() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .id("topHUD_\(currentPoints)")
    }
    
    private var dayPhaseColor: Color {
        guard let phase = viewModel.city?.dayPhase else { return .gray }
        switch phase {
        case .dawn: return Color(red: 1.0, green: 0.7, blue: 0.4)
        case .day: return Color(red: 1.0, green: 0.95, blue: 0.8)
        case .dusk: return Color(red: 0.9, green: 0.5, blue: 0.4)
        case .night: return Color(red: 0.3, green: 0.4, blue: 0.6)
        }
    }
    
    private var dayPhaseText: String {
        guard let phase = viewModel.city?.dayPhase else { return "" }
        switch phase {
        case .dawn: return "DAWN"
        case .day: return "DAY"
        case .dusk: return "DUSK"
        case .night: return "NIGHT"
        }
    }
}

// MARK: - Event Feed

struct EventFeed: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array((viewModel.simulation?.events.prefix(3) ?? []).enumerated()), id: \.element.id) { index, event in
                Text(event.message)
                    .font(.system(size: 11, weight: .light, design: .serif))
                    .foregroundColor(colorForEventType(event.type).opacity(1.0 - Double(index) * 0.3))
                    .italic()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .animation(.easeOut(duration: 0.3), value: viewModel.simulation?.events.first?.id)
    }
    
    private func colorForEventType(_ type: GameEvent.EventType) -> Color {
        switch type {
        case .observation: return .white.opacity(0.6)
        case .spread: return Color(red: 0.8, green: 0.6, blue: 0.9)
        case .response: return Color(red: 0.9, green: 0.6, blue: 0.5)
        case .milestone: return Color(red: 1.0, green: 0.85, blue: 0.4)
        case .warning: return Color(red: 1.0, green: 0.5, blue: 0.4)
        }
    }
}

// MARK: - District Panel

struct DistrictPanel: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        if let district = viewModel.selectedDistrict {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(district.activityDescription.uppercased())
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .tracking(2)
                            .foregroundColor(.white)
                        
                        Text(districtTypeLabel(district.type))
                            .font(.system(size: 10, weight: .light, design: .default))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Button(action: { viewModel.deselectDistrict() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Text(district.statusMessage)
                    .font(.system(size: 13, weight: .light, design: .serif))
                    .foregroundColor(.white.opacity(0.7))
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 16) {
                    IndicatorDot(label: "Activity", level: district.activityLevel, color: Color(red: 0.4, green: 0.7, blue: 0.5))
                    
                    if district.isSeeded {
                        IndicatorDot(label: "Change", level: district.influence, color: Color(red: 0.7, green: 0.5, blue: 0.8))
                    }
                    
                    if district.suppressionLevel > 0.1 {
                        IndicatorDot(label: "Presence", level: district.suppressionLevel, color: Color(red: 0.8, green: 0.5, blue: 0.4))
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    // Show different states for seed button
                    if let city = viewModel.city {
                        if !city.hasBeenSeeded {
                            GameActionButton(title: "SEED", icon: "target", enabled: true, style: .primary) {
                                viewModel.seedSelectedDistrict()
                            }
                        } else if district.isSeeded {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                Text("ORIGIN")
                                    .font(.system(size: 10, weight: .medium, design: .default))
                                    .tracking(1)
                            }
                            .foregroundColor(Color(red: 0.5, green: 0.7, blue: 0.5).opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "circle.dashed")
                                    .font(.system(size: 10))
                                Text("SEEDED")
                                    .font(.system(size: 10, weight: .medium, design: .default))
                                    .tracking(1)
                            }
                            .foregroundColor(Color.white.opacity(0.3))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                    }
                    
                    GameActionButton(title: "DISTURB", icon: "bolt.fill", enabled: viewModel.canDisturb, style: .warning) {
                        viewModel.disturbSelectedDistrict()
                    }
                    
                    GameActionButton(title: "DIVERT", icon: "eye.slash", enabled: viewModel.canSuppress, style: .subtle) {
                        viewModel.suppressSelectedDistrict()
                    }
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
    
    private func districtTypeLabel(_ type: DistrictType) -> String {
        switch type {
        case .residential: return "Residential"
        case .commercial: return "Commercial"
        case .industrial: return "Industrial"
        case .civic: return "Civic"
        case .park: return "Green Space"
        }
    }
}

struct IndicatorDot: View {
    let label: String
    let level: Float
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color.opacity(Double(level) * 0.8 + 0.2))
                .frame(width: CGFloat(8 + level * 12), height: CGFloat(8 + level * 12))
            
            Text(label)
                .font(.system(size: 9, weight: .light, design: .default))
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
            case .primary: return Color(red: 0.4, green: 0.7, blue: 0.5)
            case .warning: return Color(red: 0.9, green: 0.6, blue: 0.3)
            case .subtle: return Color(red: 0.5, green: 0.5, blue: 0.6)
            }
        }
    }
    
    @State private var isPressed = false
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
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .tracking(1)
            }
            .foregroundColor(enabled ? (showFeedback ? .black : .white) : .white.opacity(0.3))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(showFeedback ? style.activeColor : Color.white.opacity(enabled ? 0.1 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(enabled ? style.activeColor.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .disabled(!enabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if enabled && !isPressed {
                        withAnimation(.easeOut(duration: 0.1)) { isPressed = true }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeIn(duration: 0.1)) { isPressed = false }
                }
        )
    }
}

// MARK: - Action Bar

struct ActionBar: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: {
                withAnimation { viewModel.showMutations.toggle() }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .light))
                    Text("EVOLVE")
                        .font(.system(size: 9, weight: .medium, design: .default))
                        .tracking(1)
                }
                .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            if let mutations = viewModel.simulation?.activeMutations, !mutations.isEmpty {
                HStack(spacing: 4) {
                    ForEach(mutations.prefix(3)) { mutation in
                        Circle()
                            .fill(Color(red: mutation.tier.color.r, green: mutation.tier.color.g, blue: mutation.tier.color.b))
                            .frame(width: 6, height: 6)
                    }
                    if mutations.count > 3 {
                        Text("+\(mutations.count - 3)")
                            .font(.system(size: 9, weight: .light, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
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

// MARK: - Mutation Panel

struct MutationPanel: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State private var refreshTrigger: Bool = false
    
    var currentBalance: Int {
        viewModel.simulation?.mutationPoints ?? 0
    }
    
    var groupedMutations: [(tier: MutationTier, mutations: [Mutation])] {
        let available = viewModel.availableMutationsForPurchase
        return MutationTier.allCases.compactMap { tier in
            let mutations = available.filter { $0.tier == tier }
            return mutations.isEmpty ? nil : (tier, mutations)
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { viewModel.showMutations = false }
                }
            
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("EVOLVE")
                            .font(.system(size: 16, weight: .medium, design: .default))
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
                                .id("balance_\(currentBalance)_\(refreshTrigger)")
                        }
                    }
                    
                    if let active = viewModel.simulation?.activeMutations, !active.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ACTIVE")
                                .font(.system(size: 10, weight: .medium, design: .default))
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.4))
                            
                            ForEach(active) { mutation in
                                HStack {
                                    Circle()
                                        .fill(Color(red: mutation.tier.color.r, green: mutation.tier.color.g, blue: mutation.tier.color.b))
                                        .frame(width: 6, height: 6)
                                    Text(mutation.name)
                                        .font(.system(size: 11, weight: .light, design: .default))
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                    Text(mutation.tier.label)
                                        .font(.system(size: 8, weight: .medium, design: .default))
                                        .foregroundColor(Color(red: mutation.tier.color.r, green: mutation.tier.color.g, blue: mutation.tier.color.b).opacity(0.6))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                        
                        Divider().background(Color.white.opacity(0.1))
                    }
                    
                    // Grouped by tier
                    ForEach(groupedMutations, id: \.tier) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(group.tier.label)
                                    .font(.system(size: 10, weight: .medium, design: .default))
                                    .tracking(2)
                                    .foregroundColor(Color(red: group.tier.color.r, green: group.tier.color.g, blue: group.tier.color.b).opacity(0.8))
                                
                                Rectangle()
                                    .fill(Color(red: group.tier.color.r, green: group.tier.color.g, blue: group.tier.color.b).opacity(0.3))
                                    .frame(height: 1)
                            }
                            
                            ForEach(group.mutations) { mutation in
                                MutationCard(
                                    mutation: mutation,
                                    currentBalance: currentBalance,
                                    refreshTrigger: $refreshTrigger
                                ) {
                                    viewModel.applyMutation(mutation)
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        refreshTrigger.toggle()
                                    }
                                    
                                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                                    impact.impactOccurred()
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        withAnimation { viewModel.showMutations = false }
                    }) {
                        Text("CLOSE")
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 12)
                    }
                }
                .padding(20)
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Mutation Card

struct MutationCard: View {
    let mutation: Mutation
    let currentBalance: Int
    @Binding var refreshTrigger: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var showPurchaseFeedback = false
    
    var canAfford: Bool {
        currentBalance >= mutation.cost
    }
    
    var tierColor: Color {
        Color(red: mutation.tier.color.r, green: mutation.tier.color.g, blue: mutation.tier.color.b)
    }
    
    var body: some View {
        Button(action: {
            guard canAfford else { return }
            
            withAnimation(.easeOut(duration: 0.1)) { showPurchaseFeedback = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeIn(duration: 0.3)) { showPurchaseFeedback = false }
            }
            
            action()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mutation.name)
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .foregroundColor(canAfford ? .white : .white.opacity(0.4))
                    
                    Text(mutation.description)
                        .font(.system(size: 10, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.5))
                        .italic()
                }
                
                Spacer()
                
                HStack(spacing: 3) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 8))
                    Text("\(mutation.cost)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .foregroundColor(canAfford ? tierColor : .white.opacity(0.3))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(showPurchaseFeedback ? tierColor.opacity(0.3) : Color.white.opacity(canAfford ? 0.05 : 0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(canAfford ? tierColor.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .disabled(!canAfford)
        .id("mutation_\(mutation.id)_\(currentBalance)_\(refreshTrigger)")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if canAfford && !isPressed {
                        withAnimation(.easeOut(duration: 0.1)) { isPressed = true }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeIn(duration: 0.1)) { isPressed = false }
                }
        )
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
                        .font(.system(size: 24, weight: .thin, design: .default))
                        .tracking(8)
                        .foregroundColor(.white)
                    
                    Text(viewModel.endGameMessage)
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.6))
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                if let city = viewModel.city {
                    VStack(spacing: 16) {
                        HStack(spacing: 24) {
                            FinalStat(label: "Spread", value: "\(Int(city.globalInfluence * 100))%")
                            FinalStat(label: "Control", value: "\(Int(city.globalSuppression * 100))%")
                            FinalStat(label: "Time", value: "\(city.gameTime)")
                        }
                        
                        VStack(spacing: 4) {
                            Text("SCORE")
                                .font(.system(size: 10, weight: .medium, design: .default))
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.4))
                            Text("\(city.score)")
                                .font(.system(size: 40, weight: .thin, design: .monospaced))
                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
                        }
                    }
                }
                
                VStack(spacing: 12) {
                    MenuButton(title: "TRY AGAIN") {
                        viewModel.restartGame()
                    }
                    
                    MenuButton(title: "DIFFERENT CITY") {
                        viewModel.returnToCitySelect()
                    }
                }
            }
        }
    }
}

struct FinalStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .light, design: .default))
                .tracking(1)
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
