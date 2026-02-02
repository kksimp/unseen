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
            case .difficultySelect:
                ScenarioSelectView()
                    .transition(.move(edge: .trailing))
            case .game:
                GameView()
                    .transition(.opacity)
            case .endGame:
                EndGameView()
                    .transition(.opacity)
            }
            
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
                
                VStack(spacing: 16) {
                    Text("UNSEEN")
                        .font(.system(size: 56, weight: .thin))
                        .tracking(20)
                        .foregroundColor(.white)
                        .opacity(titleOpacity)
                    
                    Text("Ideas spread. Nations change.")
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
                            viewModel.currentScreen = .difficultySelect
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
                    let highScore = SaveManager.shared.getHighScores().first?.score ?? 0
                    
                    if totalGames > 0 {
                        Text("\(totalGames) games played • High score: \(highScore)")
                            .font(.system(size: 10, weight: .light, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                    
                    Text("v0.4")
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
                        viewModel.currentScreen = .difficultySelect
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

// MARK: - Overwrite Warning

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
                        .font(.system(size: 18, weight: .medium))
                        .tracking(3)
                        .foregroundColor(.white)
                    
                    Text("Starting a new game will erase your current progress.")
                        .font(.system(size: 13, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                
                HStack(spacing: 16) {
                    Button(action: { isPresented = false }) {
                        Text("CANCEL")
                            .font(.system(size: 12, weight: .medium))
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
                            .font(.system(size: 12, weight: .medium))
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
        ("THE IDEA", "You control the spread of an idea - a belief, a movement, a cultural shift. You'll never know exactly what it is. You only see how it changes America.", "lightbulb.fill"),
        ("SEED & SPREAD", "Tap a state and press SEED to begin. Watch as your idea spreads through social connections, media, and culture.", "target"),
        ("VECTORS", "Upgrade different vectors to spread faster:\n• Grassroots - Local, personal spread\n• Social Media - Viral, jumps anywhere\n• Mainstream - National reach\n• Institutions - Lasting change\n• Culture - Deep roots", "arrow.triangle.branch"),
        ("THE BACKLASH", "As your idea becomes visible, a counter-movement will emerge. It spreads through the same channels, competing for hearts and minds.", "arrow.left.arrow.right"),
        ("ECHO CHAMBERS", "Create echo chambers to protect believers from the counter-idea. But isolation has costs.", "repeat.circle"),
        ("VICTORY", "Win by reaching your adoption threshold before the backlash overwhelms you. Different difficulties require different levels of dominance.", "flag.checkered"),
        ("STRATEGY", "Urban states spread fast but trigger backlash. Rural states resist change. Swing states are volatile. Balance visibility with resilience.", "map")
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            
            VStack(spacing: 24) {
                HStack {
                    Text("HOW TO PLAY")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(4)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                VStack(spacing: 20) {
                    Image(systemName: pages[currentPage].icon)
                        .font(.system(size: 40, weight: .thin))
                        .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8))
                    
                    Text(pages[currentPage].title)
                        .font(.system(size: 20, weight: .medium))
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    Text(pages[currentPage].content)
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .frame(minHeight: 220)
                
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        withAnimation { currentPage = max(0, currentPage - 1) }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("BACK")
                        }
                        .font(.system(size: 12, weight: .medium))
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
                            .font(.system(size: 12, weight: .medium))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.7))
                        }
                    } else {
                        Button(action: { isPresented = false }) {
                            Text("GOT IT")
                                .font(.system(size: 12, weight: .medium))
                                .tracking(2)
                                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8))
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
                .font(.system(size: 16, weight: .medium))
                .tracking(4)
                .foregroundColor(highlight ? Color(red: 0.6, green: 0.5, blue: 0.8) : .white)
                .frame(width: 200, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(highlight ? Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.5) : Color.white.opacity(0.3), lineWidth: 1)
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

// MARK: - Scenario Select

struct ScenarioSelectView: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { viewModel.currentScreen = .menu }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text("NEW GAME")
                    .font(.system(size: 14, weight: .medium))
                    .tracking(4)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Difficulty selection
            VStack(spacing: 12) {
                Text("DIFFICULTY")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.5))
                
                HStack(spacing: 12) {
                    ForEach(GameDifficulty.allCases, id: \.self) { difficulty in
                        DifficultyButton(
                            difficulty: difficulty,
                            isSelected: viewModel.selectedDifficulty == difficulty
                        ) {
                            viewModel.selectedDifficulty = difficulty
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            Text("CHOOSE YOUR ORIGIN")
                .font(.system(size: 10, weight: .medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 12)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(GameViewModel.GameScenario.allCases, id: \.self) { scenario in
                        ScenarioCard(scenario: scenario) {
                            viewModel.selectScenario(scenario)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }
}

struct DifficultyButton: View {
    let difficulty: GameDifficulty
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(difficultyLabel)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
                
                Text("\(Int(difficulty.winThreshold * 100))%")
                    .font(.system(size: 9, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            .foregroundColor(isSelected ? Color(red: 0.6, green: 0.5, blue: 0.8) : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var difficultyLabel: String {
        switch difficulty {
        case .tippingPoint: return "EASY"
        case .culturalDominance: return "NORMAL"
        case .totalShift: return "HARD"
        }
    }
}

struct ScenarioCard: View {
    let scenario: GameViewModel.GameScenario
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: scenario.icon)
                    .font(.system(size: 24, weight: .thin))
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.rawValue.uppercased())
                        .font(.system(size: 14, weight: .medium))
                        .tracking(2)
                        .foregroundColor(.white)
                                            
                                            Text(scenario.description)
                                                .font(.system(size: 11, weight: .light, design: .serif))
                                                .foregroundColor(.white.opacity(0.5))
                                                .italic()
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .light))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // MARK: - End Game View (for endGame screen state)

                        struct EndGameView: View {
                            @EnvironmentObject var viewModel: GameViewModel
                            @State private var showContent = false
                            
                            var body: some View {
                                VStack(spacing: 40) {
                                    Spacer()
                                    
                                    VStack(spacing: 20) {
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
                                        
                                        if let usa = viewModel.usa {
                                            VStack(spacing: 8) {
                                                Text("FINAL SCORE")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .tracking(2)
                                                    .foregroundColor(.white.opacity(0.4))
                                                Text("\(viewModel.currentScore)")
                                                    .font(.system(size: 36, weight: .thin, design: .monospaced))
                                                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8))
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
                                        
                                        MenuButton(title: "NEW SCENARIO") {
                                            viewModel.returnToDifficultySelect()
                                        }
                                        
                                        Button(action: { viewModel.returnToMenu() }) {
                                            Text("MAIN MENU")
                                                .font(.system(size: 12, weight: .light))
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
