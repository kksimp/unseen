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
                
                if let usa = viewModel.usa, usa.counterIdeaActive {
                    CounterIdeaBar(strength: usa.counterIdeaStrength, adoption: usa.globalCounterAdoption)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                GlobalStatsBar().padding(.bottom, 4)
                NewsTicker().padding(.bottom, 8)
                
                if viewModel.selectedState != nil {
                    StatePanel().transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                ActionBar()
            }
            
            if showOpeningLine {
                OpeningLineOverlay(scenario: viewModel.selectedScenario ?? .random, ideaName: viewModel.usa?.ideaName?.name, opacity: openingLineOpacity)
            }
            
            if viewModel.showUpgrades { UpgradePanel().transition(.opacity) }
            if viewModel.showPauseMenu { PauseMenuOverlay().transition(.opacity) }
            if viewModel.showEndScreen { EndGameOverlay().transition(.opacity) }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeOut(duration: 1.0)) { openingLineOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showOpeningLine = false }
        }
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in mapController.updateStateVisuals() }
    }
}

struct NewsTicker: View {
    @EnvironmentObject var viewModel: GameViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array((viewModel.simulation?.newsEvents.prefix(3) ?? []).enumerated()), id: \.element.id) { index, event in
                HStack(spacing: 8) {
                    Image(systemName: iconFor(event.type)).font(.system(size: 9)).foregroundColor(colorFor(event.type))
                    Text(event.headline).font(.system(size: 11, weight: .light, design: .serif)).foregroundColor(.white.opacity(1.0 - Double(index) * 0.25)).lineLimit(1)
                    Spacer()
                    Text(event.source).font(.system(size: 8, weight: .medium)).foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.7)))
        .padding(.horizontal, 16)
    }
    func iconFor(_ t: NewsEvent.EventType) -> String {
        switch t { case .spread: return "arrow.up.right"; case .counter: return "arrow.uturn.backward"; case .milestone: return "star.fill"; case .backlash: return "exclamationmark.triangle"; case .cultural: return "theatermasks"; case .political: return "building.columns"; case .warning: return "flame" }
    }
    func colorFor(_ t: NewsEvent.EventType) -> Color {
        switch t { case .spread: return Color(red: 0.4, green: 0.85, blue: 0.55); case .counter: return Color(red: 0.9, green: 0.45, blue: 0.5); case .milestone: return Color(red: 0.6, green: 0.5, blue: 0.8); case .backlash: return Color(red: 0.9, green: 0.6, blue: 0.4); case .cultural: return Color(red: 0.6, green: 0.6, blue: 0.8); case .political: return Color(red: 0.5, green: 0.6, blue: 0.7); case .warning: return Color(red: 1.0, green: 0.5, blue: 0.4) }
    }
}

struct CounterIdeaBar: View {
    let strength: Float; let adoption: Float
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "arrow.left.arrow.right").font(.system(size: 10)).foregroundColor(Color(red: 0.9, green: 0.45, blue: 0.5))
                Text("BACKLASH").font(.system(size: 9, weight: .medium)).tracking(2).foregroundColor(Color(red: 0.9, green: 0.45, blue: 0.5))
                Spacer()
                Text("\(Int(adoption * 100))%").font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundColor(Color(red: 0.9, green: 0.45, blue: 0.5))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.9, green: 0.45, blue: 0.5).opacity(0.8)).frame(width: geo.size.width * CGFloat(adoption))
                }
            }.frame(height: 4)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.7)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.9, green: 0.45, blue: 0.5).opacity(0.3), lineWidth: 1)))
    }
}

struct PauseMenuOverlay: View {
    @EnvironmentObject var viewModel: GameViewModel
    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("PAUSED").font(.system(size: 24, weight: .thin)).tracking(8).foregroundColor(.white)
                if let n = viewModel.usa?.ideaName?.name { Text("\"\(n)\"").font(.system(size: 16, weight: .medium)).foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8)) }
                if let usa = viewModel.usa {
                    VStack(spacing: 8) {
                        Divider().background(Color.white.opacity(0.2))
                        Text("PROGRESS").font(.system(size: 10, weight: .medium)).tracking(2).foregroundColor(.white.opacity(0.5))
                        HStack(spacing: 20) {
                            VStack(spacing: 2) { Text("\(Int(usa.globalIdeaAdoption * 100))%").font(.system(size: 18, weight: .medium, design: .monospaced)).foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.55)); Text("Adoption").font(.system(size: 9, weight: .light)).foregroundColor(.white.opacity(0.5)) }
                            VStack(spacing: 2) { Text("\(Int(usa.globalCounterAdoption * 100))%").font(.system(size: 18, weight: .medium, design: .monospaced)).foregroundColor(Color(red: 0.9, green: 0.45, blue: 0.5)); Text("Backlash").font(.system(size: 9, weight: .light)).foregroundColor(.white.opacity(0.5)) }
                            VStack(spacing: 2) { Text("\(Int(usa.difficulty.winThreshold * 100))%").font(.system(size: 18, weight: .medium, design: .monospaced)).foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8)); Text("Goal").font(.system(size: 9, weight: .light)).foregroundColor(.white.opacity(0.5)) }
                        }
                        Divider().background(Color.white.opacity(0.2))
                    }.padding(.vertical, 8)
                }
                VStack(spacing: 12) {
                    PauseBtn(title: "RESUME", icon: "play.fill") { viewModel.resumeGame() }
                    PauseBtn(title: "SAVE & QUIT", icon: "square.and.arrow.down") { viewModel.saveAndQuit() }
                    PauseBtn(title: "RESTART", icon: "arrow.counterclockwise", destructive: true) { viewModel.restartGame() }
                }.padding(.top, 8)
            }
            .padding(28).background(RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.06, green: 0.06, blue: 0.08).opacity(0.98)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))).padding(.horizontal, 40)
        }
    }
}

struct PauseBtn: View {
    let title: String; let icon: String; var destructive: Bool = false; let action: () -> Void
    var body: some View {
        Button(action: { UIImpactFeedbackGenerator(style: .medium).impactOccurred(); action() }) {
            HStack(spacing: 10) { Image(systemName: icon).font(.system(size: 14, weight: .medium)); Text(title).font(.system(size: 13, weight: .medium)).tracking(2) }
                .foregroundColor(destructive ? Color(red: 1.0, green: 0.5, blue: 0.4) : .white)
                .frame(width: 180, height: 44)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)).overlay(RoundedRectangle(cornerRadius: 8).stroke(destructive ? Color(red: 1.0, green: 0.5, blue: 0.4).opacity(0.3) : Color.white.opacity(0.2), lineWidth: 1)))
        }.buttonStyle(PlainButtonStyle())
    }
}

struct GlobalStatsBar: View {
    @EnvironmentObject var viewModel: GameViewModel
    var body: some View {
        if let usa = viewModel.usa {
            HStack(spacing: 12) {
                StatPill(icon: "brain.head.profile", label: "Adoption", value: "\(Int(usa.globalIdeaAdoption * 100))%", color: Color(red: 0.4, green: 0.85, blue: 0.55))
                StatPill(icon: "map.fill", label: "States", value: "\(usa.allStates.filter { $0.ideaAdopters > 0 }.count)/51", color: Color(red: 0.6, green: 0.5, blue: 0.8))
                StatPill(icon: "person.fill.questionmark", label: "Undecided", value: "\(Int((1 - usa.globalIdeaAdoption - usa.globalCounterAdoption - usa.globalDisengaged) * 100))%", color: Color(red: 0.6, green: 0.6, blue: 0.65))
            }.padding(.horizontal, 16)
        }
    }
}

struct StatPill: View {
    let icon: String; let label: String; let value: String; let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 10)).foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) { Text(label.uppercased()).font(.system(size: 7, weight: .medium)).foregroundColor(.white.opacity(0.4)); Text(value).font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundColor(color) }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.6)).overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.3), lineWidth: 1)))
    }
}

struct OpeningLineOverlay: View {
    let scenario: GameViewModel.GameScenario; let ideaName: String?; let opacity: Double
    var body: some View {
        ZStack {
            Color.black.opacity(0.85 * opacity).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: scenario.icon).font(.system(size: 40, weight: .thin)).foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8))
                if let name = ideaName { Text("\"\(name)\"").font(.system(size: 28, weight: .medium)).foregroundColor(.white) }
                Text("An idea begins to spread...").font(.system(size: 16, weight: .light, design: .serif)).foregroundColor(.white.opacity(0.7)).italic()
            }.opacity(opacity)
        }.allowsHitTesting(false)
    }
}

struct TopHUD: View {
    @EnvironmentObject var viewModel: GameViewModel
    var body: some View {
        HStack {
            Button(action: { viewModel.togglePause() }) {
                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill").font(.system(size: 16, weight: .light)).foregroundColor(.white.opacity(0.7)).frame(width: 44, height: 44).background(Circle().fill(Color.black.opacity(0.5)))
            }
            if let n = viewModel.usa?.ideaName?.name {
                Text("\"\(n)\"").font(.system(size: 11, weight: .medium)).foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8)).padding(.horizontal, 10).padding(.vertical, 5).background(Capsule().fill(Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.15)))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let usa = viewModel.usa { Text("DAY \(usa.gameTime)").font(.system(size: 10, weight: .light, design: .monospaced)).foregroundColor(.white.opacity(0.5)) }
                if !viewModel.showUpgrades { HStack(spacing: 6) { Image(systemName: "diamond.fill").font(.system(size: 8)).foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8)); Text("\(viewModel.usa?.influencePoints ?? 0)").font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.white.opacity(0.8)) } }
            }
            Button(action: { viewModel.returnToDifficultySelect() }) { Image(systemName: "xmark").font(.system(size: 14, weight: .light)).foregroundColor(.white.opacity(0.5)).frame(width: 44, height: 44).background(Circle().fill(Color.black.opacity(0.4))) }
        }.padding(.horizontal, 16).padding(.top, 8)
    }
}

// MARK: - State Panel

struct StatePanel: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        if let state = viewModel.selectedState {
            StatePanelContent(state: state)
        }
    }
}

struct StatePanelContent: View {
    @EnvironmentObject var viewModel: GameViewModel
    let state: StateRegion
    
    var body: some View {
        VStack(spacing: 12) {
            StatePanelHeader(state: state)
            
            // Status message
            Text(state.statusMessage(ideaName: viewModel.usa?.ideaName))
                .font(.system(size: 12, weight: .light, design: .serif))
                .foregroundColor(.white.opacity(0.7))
                .italic()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Population bars
            StatePanelBars(state: state)
            
            // Unrest warning
            if state.socialUnrest > 0.3 {
                UnrestWarning(unrest: state.socialUnrest)
            }
            
            // Actions
            StatePanelActions(state: state)
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

struct StatePanelHeader: View {
    @EnvironmentObject var viewModel: GameViewModel
    let state: StateRegion
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.stateData.name.uppercased())
                    .font(.system(size: 14, weight: .medium))
                    .tracking(2)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(typeLabel)
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text(formatPopulation(state.stateData.population))
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            if state.echoChambered {
                EchoBadge()
            }
            
            Button(action: { viewModel.deselectState() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    var typeLabel: String {
        switch state.stateData.type {
        case .urban: return "Urban"
        case .suburban: return "Suburban"
        case .rural: return "Rural"
        case .swing: return "Swing State"
        }
    }
    
    func formatPopulation(_ pop: Int) -> String {
        if pop >= 1000000 {
            return String(format: "%.1fM", Float(pop) / 1000000)
        } else {
            return String(format: "%.0fK", Float(pop) / 1000)
        }
    }
}

struct EchoBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "repeat.circle.fill")
                .font(.system(size: 10))
            Text("ECHO")
                .font(.system(size: 8, weight: .medium))
                .tracking(1)
        }
        .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.7))
    }
}

struct StatePanelBars: View {
    let state: StateRegion
    
    var body: some View {
        HStack(spacing: 16) {
            PopBar(label: "Adopted", value: state.ideaAdoptionRate, color: Color(red: 0.4, green: 0.85, blue: 0.55))
            PopBar(label: "Counter", value: state.counterAdoptionRate, color: Color(red: 0.9, green: 0.45, blue: 0.5))
            PopBar(label: "Open", value: state.contestedRate, color: Color(red: 0.6, green: 0.6, blue: 0.65))
        }
    }
}

struct UnrestWarning: View {
    let unrest: Float
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
            Text("Social tension: \(Int(unrest * 100))%")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.4))
    }
}

struct StatePanelActions: View {
    @EnvironmentObject var viewModel: GameViewModel
    let state: StateRegion
    
    var body: some View {
        HStack(spacing: 12) {
            if !viewModel.hasSeeded {
                ActionBtn(title: "SEED", icon: "target", enabled: viewModel.canSeed, style: .primary) {
                    viewModel.seedSelectedState()
                }
            } else if state.ideaAdopters > 0 {
                ActionBtn(title: "AMPLIFY", icon: "speaker.wave.2.fill", enabled: viewModel.canAmplify, style: .primary) {
                    viewModel.amplifySelectedState()
                }
                
                if !state.echoChambered {
                    ActionBtn(title: "ECHO", icon: "repeat.circle", enabled: viewModel.canCreateEchoChamber, style: .subtle) {
                        viewModel.createEchoChamber()
                    }
                }
            } else {
                NotReachedText()
            }
            
            Spacer()
        }
    }
}

struct NotReachedText: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        if let idea = viewModel.usa?.ideaName {
            Text("\(idea.forHeadline) hasn't reached here yet")
                .font(.system(size: 11, weight: .light, design: .serif))
                .foregroundColor(.white.opacity(0.4))
                .italic()
        } else {
            Text("The idea hasn't reached here yet")
                .font(.system(size: 11, weight: .light, design: .serif))
                .foregroundColor(.white.opacity(0.4))
                .italic()
        }
    }
}

struct PopBar: View {
    let label: String; let value: Float; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(value * 100))%").font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(color)
            GeometryReader { geo in ZStack(alignment: .leading) { RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.1)); RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.8)).frame(width: geo.size.width * CGFloat(value)) } }.frame(height: 4)
            Text(label).font(.system(size: 8, weight: .light)).foregroundColor(.white.opacity(0.4))
        }
    }
}

struct ActionBtn: View {
    let title: String; let icon: String; let enabled: Bool; let style: Style; let action: () -> Void
    enum Style { case primary, warning, subtle; var color: Color { switch self { case .primary: return Color(red: 0.4, green: 0.85, blue: 0.55); case .warning: return Color(red: 0.9, green: 0.6, blue: 0.3); case .subtle: return Color(red: 0.6, green: 0.5, blue: 0.8) } } }
    @State private var feedback = false
    var body: some View {
        Button(action: { guard enabled else { return }; withAnimation(.easeOut(duration: 0.1)) { feedback = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { withAnimation(.easeIn(duration: 0.2)) { feedback = false } }; UIImpactFeedbackGenerator(style: .medium).impactOccurred(); action() }) {
            HStack(spacing: 6) { Image(systemName: icon).font(.system(size: 12, weight: .medium)); Text(title).font(.system(size: 11, weight: .medium)).tracking(1) }
                .foregroundColor(enabled ? (feedback ? .black : .white) : .white.opacity(0.3))
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 6).fill(feedback ? style.color : Color.white.opacity(enabled ? 0.1 : 0.03)).overlay(RoundedRectangle(cornerRadius: 6).stroke(enabled ? style.color.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1)))
        }.disabled(!enabled)
    }
}

struct ActionBar: View {
    @EnvironmentObject var viewModel: GameViewModel
    var body: some View {
        HStack(spacing: 20) {
            Button(action: { withAnimation { viewModel.showUpgrades.toggle() } }) { VStack(spacing: 4) { Image(systemName: "arrow.triangle.branch").font(.system(size: 20, weight: .light)); Text("EVOLVE").font(.system(size: 9, weight: .medium)).tracking(1) }.foregroundColor(.white.opacity(0.7)) }
            Spacer()
            if let usa = viewModel.usa { HStack(spacing: 6) { ForEach(InfluenceVector.allCases.filter { (usa.vectorLevels[$0] ?? 0) > 0.05 }) { v in Image(systemName: v.icon).font(.system(size: 10)).foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.7)) } } }
        }.padding(.horizontal, 24).padding(.vertical, 16).background(Rectangle().fill(Color.black.opacity(0.8)).ignoresSafeArea(edges: .bottom))
    }
}

struct UpgradePanel: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State private var cat: UpgradeCategory = .vectors
    var filtered: [Upgrade] { viewModel.availableUpgrades.filter { $0.category == cat } }
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea().onTapGesture { withAnimation { viewModel.showUpgrades = false } }
            VStack(spacing: 16) {
                HStack { Text("EVOLVE").font(.system(size: 16, weight: .medium)).tracking(4).foregroundColor(.white); Spacer(); HStack(spacing: 4) { Image(systemName: "diamond.fill").font(.system(size: 10)).foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8)); Text("\(viewModel.usa?.influencePoints ?? 0)").font(.system(size: 14, weight: .medium, design: .monospaced)).foregroundColor(.white) } }
                HStack(spacing: 8) { ForEach(UpgradeCategory.allCases, id: \.self) { c in Button(action: { cat = c }) { Text(c.rawValue.uppercased()).font(.system(size: 10, weight: .medium)).tracking(1).foregroundColor(cat == c ? .white : .white.opacity(0.5)).padding(.horizontal, 12).padding(.vertical, 8).background(RoundedRectangle(cornerRadius: 6).fill(cat == c ? Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.3) : Color.white.opacity(0.05))) }.buttonStyle(PlainButtonStyle()) } }
                if let usa = viewModel.usa, !usa.purchasedUpgrades.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ACTIVE").font(.system(size: 9, weight: .medium)).tracking(2).foregroundColor(.white.opacity(0.4))
                        ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(allUpgrades.filter { usa.purchasedUpgrades.contains($0.name) }) { u in HStack(spacing: 4) { Image(systemName: u.icon).font(.system(size: 9)); Text(u.name).font(.system(size: 9, weight: .medium)) }.foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.8)).padding(.horizontal, 8).padding(.vertical, 4).background(RoundedRectangle(cornerRadius: 4).fill(Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.15))) } } }
                    }
                    Divider().background(Color.white.opacity(0.1))
                }
                ScrollView {
                    VStack(spacing: 10) {
                        if filtered.isEmpty { Text("All \(cat.rawValue.lowercased()) upgrades purchased!").font(.system(size: 12, weight: .light, design: .serif)).foregroundColor(.white.opacity(0.5)).italic().padding(.vertical, 20) }
                        else { ForEach(filtered) { u in UpCard(upgrade: u, bal: viewModel.usa?.influencePoints ?? 0) { viewModel.purchaseUpgrade(u) } } }
                    }
                }.frame(maxHeight: 300)
                Button(action: { withAnimation { viewModel.showUpgrades = false } }) { Text("CLOSE").font(.system(size: 12, weight: .medium)).tracking(2).foregroundColor(.white.opacity(0.6)) }
            }.padding(20).background(RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.08, green: 0.08, blue: 0.1)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))).padding(.horizontal, 20)
        }
    }
}

struct UpCard: View {
    let upgrade: Upgrade; let bal: Int; let action: () -> Void
    @EnvironmentObject var viewModel: GameViewModel
    var afford: Bool { bal >= upgrade.cost }
    var prereqs: Bool { viewModel.usa?.purchasedUpgrades.allSatisfy { _ in upgrade.prerequisites.allSatisfy { viewModel.usa?.purchasedUpgrades.contains($0) ?? false } } ?? false }
    var avail: Bool { afford && prereqs }
    var body: some View {
        Button(action: { guard avail else { return }; UIImpactFeedbackGenerator(style: .heavy).impactOccurred(); action() }) {
            HStack {
                Image(systemName: upgrade.icon).font(.system(size: 16)).foregroundColor(avail ? Color(red: 0.6, green: 0.5, blue: 0.8) : .white.opacity(0.3)).frame(width: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text(upgrade.name).font(.system(size: 13, weight: .medium)).foregroundColor(avail ? .white : .white.opacity(0.4))
                    Text(upgrade.description).font(.system(size: 10, weight: .light, design: .serif)).foregroundColor(.white.opacity(0.5)).italic()
                    if !prereqs { Text("Requires: \(upgrade.prerequisites.joined(separator: ", "))").font(.system(size: 9, weight: .medium)).foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.4).opacity(0.7)) }
                }
                Spacer()
                HStack(spacing: 3) { Image(systemName: "diamond.fill").font(.system(size: 8)); Text("\(upgrade.cost)").font(.system(size: 12, weight: .medium, design: .monospaced)) }.foregroundColor(afford ? Color(red: 0.6, green: 0.5, blue: 0.8) : .white.opacity(0.3))
            }.padding(12).background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(avail ? 0.05 : 0.02)).overlay(RoundedRectangle(cornerRadius: 8).stroke(avail ? Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)))
        }.disabled(!avail).buttonStyle(PlainButtonStyle())
    }
}

struct EndGameOverlay: View {
    @EnvironmentObject var viewModel: GameViewModel
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Text(viewModel.endGameTitle.uppercased()).font(.system(size: 24, weight: .thin)).tracking(8).foregroundColor(.white)
                    if let n = viewModel.usa?.ideaName?.name { Text("\"\(n)\"").font(.system(size: 18, weight: .medium)).foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8)) }
                    Text(viewModel.endGameMessage).font(.system(size: 14, weight: .light, design: .serif)).foregroundColor(.white.opacity(0.6)).italic().multilineTextAlignment(.center).padding(.horizontal, 40)
                }
                if let usa = viewModel.usa {
                    VStack(spacing: 16) {
                        HStack(spacing: 24) { FinStat(label: "Adoption", value: "\(Int(usa.globalIdeaAdoption * 100))%", color: Color(red: 0.4, green: 0.85, blue: 0.55)); FinStat(label: "Backlash", value: "\(Int(usa.globalCounterAdoption * 100))%", color: Color(red: 0.9, green: 0.45, blue: 0.5)); FinStat(label: "Days", value: "\(usa.gameTime)", color: .white) }
                        VStack(spacing: 4) { Text("SCORE").font(.system(size: 10, weight: .medium)).tracking(2).foregroundColor(.white.opacity(0.4)); Text("\(viewModel.currentScore)").font(.system(size: 40, weight: .thin, design: .monospaced)).foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8)) }
                    }
                }
                VStack(spacing: 12) { MenuButton(title: "TRY AGAIN") { viewModel.restartGame() }; MenuButton(title: "NEW SCENARIO") { viewModel.returnToDifficultySelect() } }
            }
        }
    }
}

struct FinStat: View {
    let label: String; let value: String; var color: Color = .white
    var body: some View { VStack(spacing: 4) { Text(value).font(.system(size: 16, weight: .medium, design: .monospaced)).foregroundColor(color); Text(label.uppercased()).font(.system(size: 9, weight: .light)).tracking(1).foregroundColor(.white.opacity(0.4)) } }
}
