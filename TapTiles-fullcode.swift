// ============================================================
// File: TapTiles/ContentView.swift
// ============================================================
//
//  ContentView.swift
//  TapTiles
//
//  This code was co-developed with GitHub Copilot.
//

import SwiftUI
import AVFoundation

private final class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    // Runs when the player finishes the track naturally.
    let didFinishPlaying: () -> Void

    init(didFinishPlaying: @escaping () -> Void) {
        self.didFinishPlaying = didFinishPlaying
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        didFinishPlaying()
    }
}

struct ContentView: View {
    // MARK: - Stored properties

    // Tracks which screen the player is currently viewing.
    @State private var currentScreen: AppScreen = .start

    // Stores the game's state and keeps the view updated when that state changes.
    @State private var viewModel = GameViewModel()

    // Stores the song selected for the current game.
    @State private var selectedSong: GameSong?

    // Stores the volume selected in the configuration screen.
    @State private var volume = 0.75

    // Keeps the selected song's audio player alive while the game runs.
    @State private var audioPlayer: AVAudioPlayer?

    // Connects the audio player's completion callback to the game.
    @State private var audioDelegate: AudioPlayerDelegate?

    // Tracks whether this view currently receives keyboard input.
    @FocusState private var isKeyboardFocused: Bool

    // MARK: - Body

    var body: some View {
        // Places the background behind all of the game's content.
        ZStack {
            // Uses the shared game background color.
            GameTheme.background
                // Extends the background into the safe-area margins.
                .ignoresSafeArea()

            // Shows the start screen, song menu, or game.
            switch currentScreen {
            case .start:
                StartScreenView(
                    showSongMenu: {
                        currentScreen = .songSelection
                    },
                    showConfiguration: {
                        currentScreen = .configuration
                    }
                )
            case .configuration:
                ConfigurationView(volume: $volume) {
                    currentScreen = .start
                }
            case .songSelection:
                SongSelectionView(
                    selectSong: { song in
                        selectedSong = song
                        viewModel.configureSong(songId: song.id)
                        playAudio(song)
                        viewModel.resetGame()
                        viewModel.startGame()
                        currentScreen = .game
                    },
                    goBack: {
                        currentScreen = .start
                    }
                )
            case .game:
                gameView
            }
        }
        .onChange(of: volume) { _, newVolume in
            audioPlayer?.volume = Float(newVolume)
        }
        .onChange(of: viewModel.isPlaying) { _, isPlaying in
            if isPlaying {
                audioPlayer?.play()
            } else {
                audioPlayer?.pause()
            }
        }
        // Gives the game window a useful minimum size.
        .frame(minWidth: 430, minHeight: 760)
        // Allows the view to receive keyboard focus.
        .focusable()
        // Connects the focus state to the current view.
        .focused($isKeyboardFocused)
        // Sends matching keyboard presses to the handler below.
        .onKeyPress(keys: keyboardKeys, phases: .down, action: handleKeyPress)
        // Starts the game loop when this view appears.
        .task {
            // Automatically focuses the game so keyboard controls work immediately.
            isKeyboardFocused = true
            // Keeps updating the game until the view's task is cancelled.
            await viewModel.runGameLoop()
        }
    }

    // MARK: - Computed properties

    private var gameView: some View {
        // Stacks the score, health, board, and controls vertically.
        VStack(spacing: GameTheme.largeSpacing) {
            // Shows the current score, best score, and streak.
            ScoreHeaderView(viewModel: viewModel, song: selectedSong)

            // Shows the player's health in the top middle of the game.
            HealthBarView(viewModel: viewModel)

            // Displays the falling tiles and target line.
            GameBoardView(viewModel: viewModel) {
                if viewModel.isGameOver || viewModel.isWon {
                    stopAudio()
                    viewModel.resetGame()
                    if let song = selectedSong {
                        viewModel.configureSong(songId: song.id)
                        playAudio(song)
                    }
                    viewModel.startGame()
                } else {
                    viewModel.startGame()
                }
            }
                // Prevents the board from growing beyond a readable size.
                .frame(maxWidth: 520, maxHeight: 760)

            // Shows the keyboard instructions and play/pause button.
            GameControlsView(viewModel: viewModel) {
                // Stops the current round before returning to song selection.
                stopAudio()
                viewModel.resetGame()
                currentScreen = .songSelection
            }
        }
        // Adds space around the main game layout.
        .padding(GameTheme.largePadding)
    }

    private var keyboardKeys: Set<KeyEquivalent> {
        // Lists every key that the game understands.
        [
            .leftArrow,
            .upArrow,
            .downArrow,
            .rightArrow,
            KeyEquivalent("a"),
            KeyEquivalent("s"),
            KeyEquivalent("d"),
            KeyEquivalent("f")
        ]
    }

    // MARK: - Functions

    private func playAudio(_ song: GameSong) {
        stopAudio()

        let fileExtension: String
        if song.audioFileName == "expressions-of-the-mind" {
            fileExtension = "mp3"
        } else if song.audioFileName == "tragic-serenade" {
            fileExtension = "mp3"
        } else {
            fileExtension = "wav"
        }

        guard let audioURL = Bundle.main.url(
            forResource: song.audioFileName,
            withExtension: fileExtension
        ) else {
            print("Could not find audio resource: \(song.audioFileName).\(fileExtension)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: audioURL)
            player.numberOfLoops = 0
            player.volume = Float(volume)
            let delegate = AudioPlayerDelegate {
                viewModel.winGame()
            }
            player.delegate = delegate
            audioDelegate = delegate
            player.prepareToPlay()
            player.play()
            audioPlayer = player
        } catch {
            print("Could not play audio: \(error.localizedDescription)")
        }
    }

    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        audioDelegate = nil
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        // Maps the left arrow and A key to the first lane.
        if keyPress.key == .leftArrow || keyPress.key == KeyEquivalent("a") {
            viewModel.tap(column: 0)
        // Maps the up arrow and S key to the second lane.
        } else if keyPress.key == .upArrow || keyPress.key == KeyEquivalent("s") {
            viewModel.tap(column: 1)
        // Maps the down arrow and D key to the third lane.
        } else if keyPress.key == .downArrow || keyPress.key == KeyEquivalent("d") {
            viewModel.tap(column: 2)
        // Maps the right arrow and F key to the fourth lane.
        } else if keyPress.key == .rightArrow || keyPress.key == KeyEquivalent("f") {
            viewModel.tap(column: 3)
        }

        // Prevents the key press from being handled by another control.
        return .handled
    }
}

// MARK: - App screen

private enum AppScreen {
    case start
    case configuration
    case songSelection
    case game
}

#Preview {
    // Shows the main game screen in Xcode's preview canvas.
    ContentView()
}

// ============================================================
// File: TapTiles/GameBoardViews.swift
// ============================================================
//
//  GameBoardViews.swift
//  TapTiles
//
//  This code was co-developed with GitHub Copilot.
//

import SwiftUI

// MARK: - Game board

struct GameBoardView: View {
    // Reads game state so the board can display the current tiles.
    let viewModel: GameViewModel

    // Starts or restarts the round, including its selected audio.
    let startRound: () -> Void

    var body: some View {
        // Reads the board's actual size so tiles can scale correctly.
        GeometryReader { proxy in
            // Layers the lanes, target line, tiles, and overlay.
            ZStack {
                // Draws the alternating lane background.
                laneBackground

                // Places the target line at the configured progress value.
                TargetLineView()
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height * GameViewModel.targetProgress
                    )

                // Creates one visual tile for every model tile.
                ForEach(viewModel.tiles) { tile in
                    GameTileView()
                        // Gives each tile the width of one lane.
                        .frame(width: proxy.size.width / CGFloat(GameViewModel.columnCount))
                        // Places the tile in its lane and current vertical position.
                        .position(
                            x: columnCenter(for: tile.column, width: proxy.size.width),
                            y: tileYPosition(for: tile.progress, height: proxy.size.height)
                        )
                }

                // Shows the ready or game-over overlay when the game is not running.
                if viewModel.isPlaying == false {
                    GameOverlayView(viewModel: viewModel, startRound: startRound)
                }
            }
            // Rounds the corners of the entire board.
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.cornerRadius))
        }
        // Keeps the board tall and narrow like a tile game.
        .aspectRatio(0.58, contentMode: .fit)
    }

    private var laneBackground: some View {
        // Places the lanes next to one another with no horizontal gaps.
        HStack(spacing: 0) {
            // Creates one rectangle for each lane.
            ForEach(0..<GameViewModel.columnCount, id: \.self) { column in
                Rectangle()
                    // Alternates the lane brightness for easier tracking.
                    .fill(column.isMultiple(of: 2) ? GameTheme.panel : GameTheme.panel.opacity(0.55))
                    // Adds a subtle divider on the right edge of each lane.
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(.white.opacity(0.08))
                            .frame(width: 1)
                    }
            }
        }
        // Adds a line at the bottom of the board.
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.35))
                .frame(height: 2)
        }
    }

    private func columnCenter(for column: Int, width: Double) -> Double {
        // Calculates the width of one lane.
        let columnWidth = width / Double(GameViewModel.columnCount)

        // Returns the horizontal center of the requested lane.
        return columnWidth * (Double(column) + 0.5)
    }

    private func tileYPosition(for progress: Double, height: Double) -> Double {
        // Reads the shared tile height used by both the view and game logic.
        let tileHeight = GameViewModel.tileHeight

        // Starts the tile just above the visible board.
        let start = -tileHeight / 2

        // Ends the tile just above the board's bottom edge.
        let end = height - tileHeight / 2

        // Interpolates between the start and end using the tile's progress.
        return start + (end - start) * progress
    }
}

// MARK: - Game tile

struct GameTileView: View {
    var body: some View {
        // Draws the rounded rectangle used as a falling tile.
        RoundedRectangle(cornerRadius: 12)
            // Applies the shared tile color.
            .fill(GameTheme.tile)
            // Adds depth so the tile stands out from the lanes.
            .shadow(color: GameTheme.tile.opacity(0.4), radius: 12)
            // Leaves a small gap between the tile and adjacent lanes.
            .padding(.horizontal, 5)
            // Uses the same height as the game logic.
            .frame(height: GameViewModel.tileHeight)
            // Gives screen readers a useful description.
            .accessibilityLabel("Falling tile")
    }
}

// MARK: - Target line

struct TargetLineView: View {
    var body: some View {
        // Places the line segments and label in one horizontal row.
        HStack(spacing: 10) {
            Rectangle()
                // Draws the left half of the target line.
                .fill(GameTheme.accent)
                .frame(height: 3)

            Text("TAP HERE")
                // Formats the target instruction.
                .font(.caption)
                .bold()
                .foregroundStyle(GameTheme.accent)
                .fixedSize()

            Rectangle()
                // Draws the right half of the target line.
                .fill(GameTheme.accent)
                .frame(height: 3)
        }
        // Keeps the line away from the board's side edges.
        .padding(.horizontal, 12)
        // Makes the target line glow.
        .shadow(color: GameTheme.accent.opacity(0.8), radius: 8)
    }
}

// ============================================================
// File: TapTiles/GameHUDViews.swift
// ============================================================
//
//  GameHUDViews.swift
//  TapTiles
//
//  This code was co-developed with GitHub Copilot.
//

import SwiftUI

// MARK: - Game controls

struct GameControlsView: View {
    // Reads game state so the button can show play or pause.
    let viewModel: GameViewModel

    // Runs when the player leaves the current song.
    let exitToSongMenu: () -> Void

    var body: some View {
        // Places keyboard instructions and the play/pause button in one row.
        HStack(spacing: 14) {
            // Displays the first lane's keyboard controls.
            Label("A / Left", systemImage: "arrow.left")

            // Displays the second lane's keyboard controls.
            Label("S / Up", systemImage: "arrow.up")

            // Displays the third lane's keyboard controls.
            Label("D / Down", systemImage: "arrow.down")

            // Displays and highlights the fourth lane's keyboard controls.
            Label("F / Right", systemImage: "arrow.right")
                .foregroundStyle(GameTheme.accent)

            // Toggles between pausing and starting the game.
            Button {
                if viewModel.isPlaying {
                    // Stops tile movement when the game is running.
                    viewModel.pauseGame()
                } else {
                    // Starts or resumes tile movement when paused.
                    viewModel.startGame()
                }
            } label: {
                // Changes the icon to match the current game state.
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .frame(minWidth: 48, minHeight: 48)
            }
            // Uses the platform's bordered prominent button style.
            .buttonStyle(.borderedProminent)
            // Applies the shared accent color.
            .tint(GameTheme.accent)
            // Keeps the button symbol dark against the accent color.
            .foregroundStyle(.black)
            // Gives VoiceOver a meaningful button name.
            .accessibilityLabel(viewModel.isPlaying ? "Pause game" : "Start game")

            // Returns to the song menu.
            Button("Exit", systemImage: "xmark", action: exitToSongMenu)
                .buttonStyle(.bordered)
                .tint(.white)
        }
        // Uses compact text for the control row.
        .font(.caption)
        // Makes the labels easier to read.
        .bold()
        // Uses a muted color for secondary controls.
        .foregroundStyle(.white.secondary)
    }
}

// MARK: - Health bar

struct HealthBarView: View {
    // Reads the current health so the line updates during play.
    let viewModel: GameViewModel

    var body: some View {
        // Keeps the health line centered above the board.
        VStack(spacing: 4) {
            // Uses a white line whose length represents remaining health.
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    // Draws the empty part of the health line.
                    Capsule()
                        .fill(.white.opacity(0.2))

                    // Draws the remaining health in white.
                    Capsule()
                        .fill(.white)
                        .frame(
                            width: proxy.size.width
                                * CGFloat(viewModel.health)
                                / CGFloat(GameViewModel.maximumHealth)
                        )
                }
            }
            .frame(width: 160, height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Health")
        .accessibilityValue("\(viewModel.health) out of \(GameViewModel.maximumHealth)")
    }
}

// MARK: - Game overlay

struct GameOverlayView: View {
    // Reads game state to display the correct overlay message.
    let viewModel: GameViewModel

    // Starts or restarts the round and its selected audio.
    let startRound: () -> Void

    var body: some View {
        // Stacks the icon, message, score, and action button.
        VStack(spacing: 12) {
            // Shows a different symbol before and after game over or victory.
            Image(systemName: viewModel.isWon ? "trophy.fill" : viewModel.isGameOver ? "flag.checkered" : "music.note")
                .font(.system(size: 38))
                .foregroundStyle(viewModel.isWon ? GameTheme.accent : viewModel.isGameOver ? GameTheme.danger : GameTheme.accent)

            // Changes the heading based on whether a round has ended.
            Text(viewModel.isWon ? "You Win!" : viewModel.isGameOver ? "Game Over" : "Ready?")
                .font(.title)
                .bold()
                .foregroundStyle(.white)

            // Shows the score after game over or instructions before starting.
            Text(viewModel.isWon ? "Song complete!\nScore: \(viewModel.score)" : viewModel.isGameOver ? "Score: \(viewModel.score)" : "Tap each tile before it reaches the bottom")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.secondary)

            // Starts a new round or restarts the previous round.
            Button(viewModel.isGameOver || viewModel.isWon ? "Play Again" : "Start Game", action: startRound)
                .buttonStyle(.borderedProminent)
                .tint(GameTheme.accent)
                .foregroundStyle(.black)
                .controlSize(.large)
                // Allows Return/Enter to activate the button.
                .keyboardShortcut(.return)
        }
        // Adds space inside the overlay card.
        .padding(28)
        // Gives the overlay a dark rounded background.
        .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: GameTheme.cornerRadius))
        // Keeps the card away from the board edges.
        .padding(24)
    }
}

// MARK: - Score header

struct ScoreHeaderView: View {
    // Reads the current score values from the game model.
    let viewModel: GameViewModel

    // Stores the selected song shown above the board.
    let song: GameSong?

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                // Groups the selected song and round title together.
                VStack(alignment: .leading, spacing: 3) {
                    Text("TAP TILES")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)

                    if let song {
                        Text(song.title)
                            .font(.title3)
                            .bold()
                            .foregroundStyle(GameTheme.accent)
                    }
                }

                Spacer()

                // Shows the main score in a large, padded rhythm-game style.
                VStack(alignment: .trailing, spacing: 2) {
                    Text("SCORE")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.white.secondary)

                    Text(String(format: "%07d", viewModel.score))
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
            }

            HStack(spacing: 12) {
                ScoreChip(title: "COMBO", value: "\(viewModel.streak)")
                ScoreChip(title: "ACCURACY", value: String(format: "%.1f%%", viewModel.accuracy))
                ScoreChip(title: "BEST", value: "\(viewModel.bestScore)")

                Spacer()

                // Uses a large letter rank as the main performance marker.
                Text(viewModel.rank)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(GameTheme.accent)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.10), in: Circle())
                    .overlay(
                        Circle()
                            .stroke(GameTheme.accent.opacity(0.75), lineWidth: 2)
                    )
                    .accessibilityLabel("Rank \(viewModel.rank)")
            }
        }
    }
}

// MARK: - Score chip

struct ScoreChip: View {
    // Stores the label and value shown in one compact scoreboard chip.
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .bold()
                .foregroundStyle(.white.secondary)

            Text(value)
                .font(.headline)
                .bold()
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Score item

struct ScoreItem: View {
    // Stores the label shown above the number.
    let title: String

    // Stores the formatted score value.
    let value: String

    var body: some View {
        // Stacks the label and number vertically.
        VStack(spacing: 3) {
            // Shows the score category.
            Text(title)
                .font(.caption)
                .bold()
                .foregroundStyle(.white.secondary)

            // Shows the score number with a numeric transition.
            Text(value)
                .font(.title3)
                .bold()
                .foregroundStyle(GameTheme.accent)
                .contentTransition(.numericText())
        }
    }
}

// ============================================================
// File: TapTiles/GameSupport.swift
// ============================================================
//
//  GameSupport.swift
//  TapTiles
//
//  This code was co-developed with GitHub Copilot.
//

import SwiftUI

// MARK: - Game tile

struct GameTile: Identifiable, Equatable {
    // Gives SwiftUI a stable identity for this tile.
    let id: UUID

    // Stores which lane the tile belongs to.
    let column: Int

    // Stores how far the tile has traveled from top to bottom.
    var progress: Double

    init(column: Int, progress: Double = 0) {
        // Creates a unique identifier for this tile.
        self.id = UUID()

        // Saves the lane selected by the game logic.
        self.column = column

        // Starts the tile at the requested progress value.
        self.progress = progress
    }
}

// MARK: - Game song

struct GameSong: Identifiable, Hashable {
    // Gives each song a stable identity for SwiftUI lists.
    let id: String

    // Stores the name shown in the song menu.
    let title: String

    // Stores the artist or description shown below the title.
    let subtitle: String

    // Stores the formatted length shown below the author.
    let duration: String

    // Stores the audio resource bundled with the app.
    let audioFileName: String

    // Provides the songs currently available in the menu.
    static let availableSongs = [
        GameSong(
            id: "expressions-of-the-mind",
            title: "Expressions of the Mind",
            subtitle: "Piano loop by ShadyDave",
            duration: "0:51",
            audioFileName: "expressions-of-the-mind"
        ),
        GameSong(
            id: "rock-drums-swing",
            title: "Rock Drums Swing",
            subtitle: "160 BPM by Carlos Eton",
            duration: "2:58",
            audioFileName: "rock-drums-swing"
        ),
        GameSong(
            id: "progression1-glass-style",
            title: "Progression 1",
            subtitle: "Glass style by WKAlmar",
            duration: "1:00",
            audioFileName: "progression1-glass-style"
        ),
        GameSong(
            id: "tragic-serenade",
            title: "Tragic Serenade",
            subtitle: "By Vira Miller",
            duration: "2:33",
            audioFileName: "tragic-serenade"
        )
    ]
}

// MARK: - Game theme

enum GameTheme {
    // Provides the dark color behind the game.
    static let background = Color(red: 0.04, green: 0.05, blue: 0.10)

    // Provides the alternating lane background color.
    static let panel = Color.white.opacity(0.08)

    // Provides the main tile color.
    static let tile = Color(red: 0.12, green: 0.75, blue: 0.95)

    // Provides the game-over color.
    static let danger = Color(red: 1.0, green: 0.30, blue: 0.36)

    // Provides the target line and button accent color.
    static let accent = Color(red: 0.97, green: 0.73, blue: 0.24)

    // Controls the standard spacing between major views.
    static let largeSpacing = 18.0

    // Controls the padding around the main game layout.
    static let largePadding = 24.0

    // Controls the corner radius used by panels and overlays.
    static let cornerRadius = 16.0
}

// ============================================================
// File: TapTiles/GameViewModel.swift
// ============================================================
//
//  GameViewModel.swift
//  TapTiles
//
//  This code was co-developed with GitHub Copilot.
//

import Foundation
import Observation

@MainActor
@Observable
final class GameViewModel {
    // MARK: - Stored properties

    // Defines the number of lanes in the game.
    static let columnCount = 4

    // Defines the logical height used for movement calculations.
    static let laneHeight = 760.0

    // Defines how tall each tile appears on screen.
    static let tileHeight = 70.0

    // Places the target line 72% of the way down the board.
    static let targetProgress = 0.72

    // Allows a small amount of extra space around the target line.
    static let tapTolerancePixels = 30.0

    // Stores every tile currently falling on the board.
    private(set) var tiles: [GameTile] = []

    // Stores the player's score for the current round.
    private(set) var score = 0

    // Stores the highest score reached during this app session.
    private(set) var bestScore = 0

    // Counts successful taps in a row.
    private(set) var streak = 0

    // Counts correct tiles hit during the round.
    private(set) var successfulHits = 0

    // Counts wrong taps and tiles that reach the bottom.
    private(set) var missedHits = 0

    // Calculates the player's live hit accuracy.
    var accuracy: Double {
        let totalHits = successfulHits + missedHits
        if totalHits == 0 {
            return 100
        }

        return Double(successfulHits) / Double(totalHits) * 100
    }

    // Returns a letter rank based on live accuracy.
    var rank: String {
        if accuracy >= 95 {
            return "S"
        } else if accuracy >= 90 {
            return "A"
        } else if accuracy >= 80 {
            return "B"
        } else if accuracy >= 70 {
            return "C"
        } else if accuracy >= 60 {
            return "D"
        } else {
            return "F"
        }
    }

    // Stores the player's current health.
    private(set) var health = 12

    // Sets the maximum health for every round.
    static let maximumHealth = 12

    // Indicates whether the game is currently moving tiles.
    private(set) var isPlaying = false

    // Indicates whether a tile reached the bottom without being tapped.
    private(set) var isGameOver = false

    // Indicates whether the player completed the entire song.
    private(set) var isWon = false

    // Remembers which lane contained the tile that ended the game.
    private(set) var missedColumn: Int?

    // Records the time of the previous game-loop update.
    private var lastUpdate = Date()

    // Accumulates time until it is time to create another tile.
    private var spawnAccumulator = 0.0

    // Stores the time between beats for the selected song.
    private var beatInterval = 0.5

    // Stores a repeating lane pattern for the selected song.
    private var lanePattern: [Int] = [0, 1, 2, 3]

    // Tracks the next lane in the selected song's pattern.
    private var nextLaneIndex = 0

    var speed: Double {
        // Uses four beats of lead time so tiles reach the line with the rhythm.
        0.72 / (beatInterval * 4)
    }

    var spawnInterval: Double {
        // Uses the selected song's beat interval for tile timing.
        beatInterval
    }

    // MARK: - Functions

    func runGameLoop() async {
        // Continues until SwiftUI cancels this view's task.
        while !Task.isCancelled {
            // Waits about 16 milliseconds, which is close to 60 updates per second.
            try? await Task.sleep(for: .milliseconds(16))

            // Resets the timer while the game is paused.
            guard isPlaying else {
                lastUpdate = Date()
                continue
            }

            // Gets the current time for this update.
            let now = Date()

            // Measures how much time passed since the previous update.
            let elapsed = now.timeIntervalSince(lastUpdate)

            // Saves this update's time for the next calculation.
            lastUpdate = now

            // Moves existing tiles and possibly creates a new tile.
            update(elapsed: elapsed)
        }
    }

    func startGame() {
        // A new game starts from zero after a game-over screen.
        if isGameOver || isWon {
            resetGame()
        }

        // Allows the game loop to move tiles.
        isPlaying = true

        // Clears the game-over state.
        isGameOver = false
        isWon = false

        // Prevents a long paused duration from moving tiles immediately.
        lastUpdate = Date()
    }

    func configureSong(songId: String) {
        // Uses a steady beat pattern that matches each song's tempo.
        if songId == "expressions-of-the-mind" {
            beatInterval = 0.667
            lanePattern = [0, 2, 1, 3, 1, 2, 0, 3]
        } else if songId == "rock-drums-swing" {
            beatInterval = 0.375
            lanePattern = [0, 1, 3, 1, 2, 3, 0, 2]
        } else if songId == "progression1-glass-style" {
            beatInterval = 0.627
            lanePattern = [0, 3, 1, 2, 3, 1, 0, 2]
        } else if songId == "tragic-serenade" {
            beatInterval = 0.75
            lanePattern = [0, 1, 2, 1, 3, 2, 1, 0]
        } else {
            beatInterval = 0.5
            lanePattern = [0, 1, 2, 3]
        }

        spawnAccumulator = 0
        nextLaneIndex = 0
    }

    func pauseGame() {
        // Stops movement without deleting the current tiles.
        isPlaying = false
    }

    func resetGame() {
        // Removes all tiles from the board.
        tiles = []

        // Resets the round score.
        score = 0

        // Resets the consecutive-hit count.
        streak = 0

        // Resets hit accuracy for the new round.
        successfulHits = 0
        missedHits = 0

        // Restores the player's health to its maximum.
        health = Self.maximumHealth

        // Clears the lane that caused the previous game over.
        missedColumn = nil

        // Returns the game to its ready state.
        isGameOver = false
        isWon = false
        isPlaying = false

        // Starts tile spawning from the beginning of its interval.
        spawnAccumulator = 0
        nextLaneIndex = 0

        // Restarts time tracking from now.
        lastUpdate = Date()
    }

    func winGame() {
        // Stops gameplay after the selected song reaches the end.
        isPlaying = false

        // Shows the victory state only if the round is still active.
        guard isGameOver == false else {
            return
        }

        isWon = true
    }

    func tap(column: Int) {
        // Ignores input when the game is paused or over.
        guard isPlaying, isGameOver == false, isWon == false else {
            return
        }

        // Finds a tile touching the target line in the selected lane.
        guard let tileIndex = tappableTileIndex(in: column) else {
            // Removes one health point when the player taps where no tile can be hit.
            loseHealth(amount: 1)
            return
        }

        // Awards more points while the player maintains a combo.
        let comboBonus = min(streak * 10, 500)
        score += 100 + comboBonus

        // Restores one health point after a successful tap without exceeding the cap.
        health = min(Self.maximumHealth, health + 1)

        // Increases the consecutive-hit count.
        streak += 1

        // Saves the highest score reached so far.
        bestScore = max(bestScore, score)

        // Removes the tile that was successfully tapped.
        tiles.remove(at: tileIndex)
        successfulHits += 1
    }

    private func update(elapsed: Double) {
        // Builds a new array containing the moved versions of the tiles.
        var updatedTiles: [GameTile] = []

        // Updates every tile one at a time.
        for tile in tiles {
            // Makes a copy so the tile's progress can be changed safely.
            var updatedTile = tile

            // Moves the tile according to elapsed time and current speed.
            updatedTile.progress += elapsed * speed

            // Ends the game if this tile has reached the bottom.
            if updatedTile.progress >= 1 {
                handleMissedTile(updatedTile)
                return
            }

            // Keeps the moved tile for the next frame.
            updatedTiles.append(updatedTile)
        }

        // Replaces the old tile list with the updated positions.
        tiles = updatedTiles

        // Adds this frame's time toward the next tile spawn.
        spawnAccumulator += elapsed

        // Creates a tile when enough time has accumulated.
        if spawnAccumulator >= spawnInterval {
            // Starts counting toward the following spawn.
            spawnAccumulator = 0

            // Adds a tile in an available lane.
            spawnTile()
        }
    }

    private func spawnTile() {
        // Chooses the next lane from the selected song's fixed pattern.
        let column = lanePattern[nextLaneIndex]
        nextLaneIndex += 1
        if nextLaneIndex >= lanePattern.count {
            nextLaneIndex = 0
        }

        // Adds a new tile at the top of the board.
        tiles.append(GameTile(column: column))
    }

    private func tappableTileIndex(in column: Int) -> Int? {
        // Stores the closest matching tile found so far.
        var bestIndex: Int?

        // Converts the forgiveness distance from pixels to progress units.
        let tapTolerance = Self.tapTolerancePixels / Self.laneHeight

        // Converts the tile's height from pixels to progress units.
        let tileProgressHeight = Self.tileHeight / Self.laneHeight

        // Checks every tile for overlap with the target line.
        for tileIndex in tiles.indices {
            let tile = tiles[tileIndex]

            // Calculates the tile's top edge in progress units.
            let tileTop = tile.progress - tileProgressHeight

            // The tile's progress represents its bottom edge.
            let tileBottom = tile.progress

            // Calculates the forgiving upper edge of the target area.
            let targetTop = Self.targetProgress - tapTolerance

            // Calculates the forgiving lower edge of the target area.
            let targetBottom = Self.targetProgress + tapTolerance

            // True means some part of the tile overlaps the target area.
            let touchesTarget = tileTop <= targetBottom && tileBottom >= targetTop

            // Only tiles in the selected lane can be tapped.
            if tile.column == column && touchesTarget {
                // Compares this tile with the closest matching tile already found.
                if let currentBestIndex = bestIndex {
                    if tiles[tileIndex].progress < tiles[currentBestIndex].progress {
                        bestIndex = tileIndex
                    }
                } else {
                    // Uses the first matching tile when no candidate exists yet.
                    bestIndex = tileIndex
                }
            }
        }

        // Returns the best tile to remove, or nil if no tile can be tapped.
        return bestIndex
    }

    private func handleMissedTile(_ tile: GameTile) {
        // Removes the missed tile so it cannot reduce health more than once.
        if let tileIndex = tiles.firstIndex(where: { existingTile in
            existingTile.id == tile.id
        }) {
            tiles.remove(at: tileIndex)
        }

        // Stores the lane that was missed for future UI use.
        missedColumn = tile.column

        // Removes four health points when a tile reaches the bottom.
        loseHealth(amount: 3)
    }

    private func loseHealth(amount: Int) {
        // Breaks the combo and records the missed hit.
        streak = 0
        missedHits += 1

        // Removes the requested health amount without allowing health to become negative.
        health = max(0, health - amount)

        // Keeps the game running while the player still has health remaining.
        guard health == 0 else {
            return
        }

        // Stops the game loop from moving more tiles.
        isPlaying = false

        // Shows the game-over overlay.
        isGameOver = true

        // Breaks the successful-tap streak.
        streak = 0
    }
}

// ============================================================
// File: TapTiles/SongMenuViews.swift
// ============================================================
//
//  SongMenuViews.swift
//  TapTiles
//
//  This code was co-developed with GitHub Copilot.
//

import SwiftUI

// MARK: - Start screen

struct StartScreenView: View {
    // Runs when the player chooses to open the song menu.
    let showSongMenu: () -> Void

    // Runs when the player chooses to open configuration.
    let showConfiguration: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundStyle(GameTheme.accent)

            VStack(spacing: 8) {
                Text("TAP TILES")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)

                Text("Choose a song and keep the rhythm going.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.secondary)
            }

            Button("Choose Song", action: showSongMenu)
                .buttonStyle(.borderedProminent)
                .tint(GameTheme.accent)
                .foregroundStyle(.black)
                .controlSize(.large)
                .keyboardShortcut(.return)

            Button("Configuration", systemImage: "gearshape", action: showConfiguration)
                .buttonStyle(.bordered)
                .tint(.white)
        }
        .padding(40)
        .frame(maxWidth: 430)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: GameTheme.cornerRadius))
        .padding(GameTheme.largePadding)
    }
}

// MARK: - Configuration

struct ConfigurationView: View {
    // MARK: - Stored properties

    // Stores the selected volume level from 0 to 1.
    @Binding var volume: Double

    // Runs when the player returns to the starting screen.
    let goBack: () -> Void

    // Tracks whether the settings or credits tab is visible.
    @State private var selectedTab = ConfigurationTab.settings

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Text("CONFIGURATION")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)

            Picker("Configuration section", selection: $selectedTab) {
                Text("Settings").tag(ConfigurationTab.settings)
                Text("Credits").tag(ConfigurationTab.credits)
            }
            .pickerStyle(.segmented)
            .frame(width: 300)

            if selectedTab == .settings {
                settingsView
            } else {
                creditsView
            }

            Button("Back", systemImage: "chevron.left", action: goBack)
                .buttonStyle(.bordered)
                .tint(.white)
        }
        .padding(32)
        .frame(width: 430)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: GameTheme.cornerRadius))
        .padding(GameTheme.largePadding)
    }

    // MARK: - Computed properties

    private var settingsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Volume", systemImage: "speaker.wave.2")
                    .foregroundStyle(.white)

                Spacer()

                Text("\(Int(volume * 100))%")
                    .foregroundStyle(.white.secondary)
            }

            Slider(value: $volume, in: 0...1)
                .tint(GameTheme.accent)
                .accessibilityLabel("Volume")
                .accessibilityValue("\(Int(volume * 100)) percent")
        }
        .frame(width: 300)
    }

    private var creditsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Audio Credits", systemImage: "person.2")
                .foregroundStyle(.white)

            ScrollView {
                Text(audioAttributions)
                    .font(.caption)
                    .textSelection(.enabled)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 300, height: 180)
            .padding(10)
            .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
            .accessibilityLabel("Audio credits")
        }
        .frame(width: 300)
    }

    private var audioAttributions: String {
        """
Expressions of the Mind (Piano Loop) by ShadyDave
https://freesound.org/s/325647/
License: Attribution NonCommercial 4.0

Rock Drums Swing 160 BPM.wav by carloseton
https://freesound.org/s/702006/
License: Creative Commons 0

Tragic Serenade by ViraMiller
https://freesound.org/s/748567/
License: Attribution 4.0

Progression1 Glass Style by wkalmar
https://freesound.org/s/732726/
License: Creative Commons 0

AI Statement: AI-assisted tools were used during the development of this app.
"""
    }
}

// MARK: - Configuration tab

private enum ConfigurationTab {
    case settings
    case credits
}

// MARK: - Song menu

struct SongSelectionView: View {
    // Runs when the player selects a song.
    let selectSong: (GameSong) -> Void

    // Runs when the player returns to the starting screen.
    let goBack: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Text("SELECT A SONG")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
            }

            VStack(spacing: 10) {
                ForEach(GameSong.availableSongs) { song in
                    Button {
                        selectSong(song)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "music.note")
                                .foregroundStyle(GameTheme.accent)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(song.title)
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Text(song.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.white.secondary)

                                Text(song.duration)
                                    .font(.caption2)
                                    .foregroundStyle(.white.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.white.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("Back", systemImage: "chevron.left", action: goBack)
                .buttonStyle(.bordered)
                .tint(.white)
        }
        .padding(28)
        .frame(maxWidth: 430)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: GameTheme.cornerRadius))
        .padding(GameTheme.largePadding)
    }
}

// ============================================================
// File: TapTiles/TapTilesApp.swift
// ============================================================
//
//  TapTilesApp.swift
//  TapTiles
//
//  This code was co-developed with GitHub Copilot.
//

import SwiftUI

@main
struct TapTilesApp: App {
    // MARK: - Body

    var body: some Scene {
        // Creates the app's main window.
        WindowGroup {
            // Places the main game screen inside the window.
            ContentView()
        }
    }
}
