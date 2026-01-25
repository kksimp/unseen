import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State private var showHowToPlay = false
    
    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.07, blue: 0.09)
                .ignoresSafeArea()
            
            switch viewModel.currentScreen {
            case .menu:
                MainMenuView(showHowToPlay: $showHowToPlay)
                    .transition(.opacity)
            case .citySelect:
                CitySelectView()
                    .transition(.move(edge: .trailing))
            case .game:
                GameView()
                    .transition(.opacity)
            case .endGame:
                EndGameView()
                    .transition(.opacity)
            }
            
            // How To Play overlay
            if showHowToPlay {
                HowToPlayView(isPresented: $showHowToPlay)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentScreen)
        .animation(.easeInOut(duration: 0.3), value: showHowToPlay)
    }
}

// MARK: - Main Menu

struct MainMenuView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @Binding var showHowToPlay: Bool
    @State private var titleOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var showOverwriteWarning: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 12) {
                    Text("UNSEEN")
                        .font(.system(size: 56, weight: .thin, design: .default))
                        .tracking(20)
                        .foregroundColor(.white)
                        .opacity(titleOpacity)
                    
                    Text("You never see it. You only see what it does.")
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .foregroundColor(Color.white.opacity(0.5))
                        .italic()
                        .opacity(taglineOpacity)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    if viewModel.hasActiveSave {
                        MenuButton(title: "CONTINUE", highlight: true) {
                            viewModel.continueGame()
                        }
                    }
                    
                    MenuButton(title: "NEW GAME") {
                        if viewModel.hasActiveSave {
                            showOverwriteWarning = true
                        } else {
                            viewModel.currentScreen = .citySelect
                        }
                    }
                    
                    MenuButton(title: "HOW TO PLAY") {
                        showHowToPlay = true
                    }
                }
                .opacity(buttonsOpacity)
                
                Spacer()
                
                VStack(spacing: 4) {
                    let totalGames = SaveManager.shared.getTotalGamesPlayed()
                    let citiesCompleted = SaveManager.shared.getTotalCitiesCompleted()
                    
                    if totalGames > 0 {
                        Text("\(totalGames) games played • \(citiesCompleted)/10 cities mastered")
                            .font(.system(size: 10, weight: .light, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                    
                    Text("v0.3")
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.2))
                }
                .padding(.bottom, 20)
            }
            
            if showOverwriteWarning {
                OverwriteWarningModal(
                    isPresented: $showOverwriteWarning,
                    onConfirm: {
                        showOverwriteWarning = false
                        viewModel.currentScreen = .citySelect
                    }
                )
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.5)) { titleOpacity = 1 }
            withAnimation(.easeIn(duration: 1.5).delay(0.5)) { taglineOpacity = 1 }
            withAnimation(.easeIn(duration: 0.8).delay(1.2)) { buttonsOpacity = 1 }
        }
    }
}
// MARK: - OverWrite Warning

struct OverwriteWarningModal: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.3))
                
                VStack(spacing: 8) {
                    Text("OVERWRITE SAVE?")
                        .font(.system(size: 18, weight: .medium, design: .default))
                        .tracking(3)
                        .foregroundColor(.white)
                    
                    Text("Starting a new game will erase your current progress. This cannot be undone.")
                        .font(.system(size: 13, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                
                HStack(spacing: 16) {
                    Button(action: { isPresented = false }) {
                        Text("CANCEL")
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Button(action: onConfirm) {
                        Text("NEW GAME")
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .tracking(2)
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(red: 1.0, green: 0.7, blue: 0.3))
                            )
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - How To Play

struct HowToPlayView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    let pages: [(title: String, content: String, icon: String)] = [
        ("THE MYSTERY", "You control something unseen - an idea, a habit, a belief, a change. You'll never know exactly what it is. You only see what it does to the city.", "eye.slash"),
        ("SEED & SPREAD", "Tap a district and press SEED to begin. Watch as your influence spreads through connected areas. The city will react.", "target"),
        ("OBSERVE", "People vanish from streets. Traffic patterns change. Authorities respond. These visual clues tell you how your influence is spreading.", "eye"),
        ("DISTURB & DIVERT", "Use DISTURB to create chaos in a district - stress rises, activity spikes. Use DIVERT to draw attention away, slowing detection.", "bolt.fill"),
        ("EVOLVE", "Earn points over time. Spend them on mutations that change how your influence behaves. Each has tradeoffs.", "sparkles"),
        ("OUTCOMES", "Total Saturation: It's everywhere.\nStrange Balance: Coexistence.\nSystem Collapse: Too much strain.\nEradication: They stopped it.", "flag.checkered"),
        ("STRATEGY", "Each city has different characteristics. Stillwater is patient. Crossway spreads fast. Hightown watches closely. Learn their patterns.", "map")
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("HOW TO PLAY")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .tracking(4)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Page content
                VStack(spacing: 20) {
                    Image(systemName: pages[currentPage].icon)
                        .font(.system(size: 40, weight: .thin))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
                    
                    Text(pages[currentPage].title)
                        .font(.system(size: 20, weight: .medium, design: .default))
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    Text(pages[currentPage].content)
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .frame(minHeight: 200)
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                
                // Navigation
                HStack(spacing: 20) {
                    Button(action: {
                        withAnimation { currentPage = max(0, currentPage - 1) }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("BACK")
                        }
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .tracking(2)
                        .foregroundColor(currentPage > 0 ? .white.opacity(0.7) : .white.opacity(0.2))
                    }
                    .disabled(currentPage == 0)
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation { currentPage += 1 }
                        }) {
                            HStack {
                                Text("NEXT")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.7))
                        }
                    } else {
                        Button(action: { isPresented = false }) {
                            Text("GOT IT")
                                .font(.system(size: 12, weight: .medium, design: .default))
                                .tracking(2)
                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
                        }
                    }
                }
            }
            .padding(24)
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

struct MenuButton: View {
    let title: String
    var highlight: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .default))
                .tracking(4)
                .foregroundColor(highlight ? Color(red: 1.0, green: 0.85, blue: 0.4) : .white)
                .frame(width: 200, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(highlight ? Color(red: 1.0, green: 0.85, blue: 0.4).opacity(0.5) : Color.white.opacity(0.3), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(isPressed ? 0.1 : 0.03))
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeOut(duration: 0.1)) { isPressed = pressing }
        }, perform: {})
    }
}

// MARK: - City Select

struct CitySelectView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State private var selectedCity: CityScenario?
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { viewModel.currentScreen = .menu }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text("SELECT CITY")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .tracking(4)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    // Random City FIRST
                    Button(action: {
                        viewModel.selectCity(.unknown)
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 80)
                                
                                Image(systemName: "dice.fill")
                                    .font(.system(size: 32, weight: .thin))
                                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
                            }
                            
                            Text("RANDOM CITY")
                                .font(.system(size: 12, weight: .medium, design: .default))
                                .tracking(2)
                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
                            
                            Text("Unknown parameters. True chaos.")
                                .font(.system(size: 10, weight: .light, design: .serif))
                                .foregroundColor(.white.opacity(0.5))
                                .italic()
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(red: 1.0, green: 0.85, blue: 0.4).opacity(0.3), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.02))
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Then all other cities
                    ForEach(CityScenario.allCases.filter { $0 != .unknown }) { scenario in
                        CityCard(scenario: scenario, isSelected: selectedCity == scenario) {
                            withAnimation(.easeOut(duration: 0.2)) { selectedCity = scenario }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.selectCity(scenario)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
}

struct CityCard: View {
    let scenario: CityScenario
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 80)
                    
                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.white.opacity(Double.random(in: 0.1...0.3)))
                                .frame(width: 12, height: CGFloat.random(in: 20...60))
                        }
                    }
                    
                    if SaveManager.shared.isCityCompleted(scenario) {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.5))
                                    .padding(6)
                            }
                            Spacer()
                        }
                    }
                }
                
                Text(scenario.rawValue.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .tracking(2)
                    .foregroundColor(.white)
                
                Text(scenario.openingLine)
                    .font(.system(size: 10, weight: .light, design: .serif))
                    .foregroundColor(.white.opacity(0.5))
                    .italic()
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let highScore = viewModel.getHighScore(for: scenario) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
                        Text("\(highScore)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.white.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(isSelected ? 0.08 : 0.02))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - End Game

struct EndGameView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
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
                
                if let city = viewModel.city {
                    VStack(spacing: 8) {
                        Text("FINAL SCORE")
                            .font(.system(size: 10, weight: .medium, design: .default))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.4))
                        Text("\(city.score)")
                            .font(.system(size: 36, weight: .thin, design: .monospaced))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
                    }
                    .padding(.top, 10)
                }
            }
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            VStack(spacing: 16) {
                MenuButton(title: "TRY AGAIN") {
                    viewModel.restartGame()
                }
                
                MenuButton(title: "DIFFERENT CITY") {
                    viewModel.returnToCitySelect()
                }
                
                Button(action: { viewModel.returnToMenu() }) {
                    Text("MAIN MENU")
                        .font(.system(size: 12, weight: .light, design: .default))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.top, 8)
            }
            .opacity(showContent ? 1 : 0)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0).delay(0.5)) { showContent = true }
        }
    }
}


