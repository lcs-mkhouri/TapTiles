 
 
 
 
 
 
 
 
 

import SwiftUI
import AVFoundation

private final class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {

    let didFinishPlaying: () -> Void

    init(didFinishPlaying: @escaping () -> Void) {
        self.didFinishPlaying = didFinishPlaying
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        didFinishPlaying()
    }
}

struct ContentView: View {



    @State private var currentScreen: AppScreen = .start


    @State private var viewModel = GameViewModel()


    @State private var selectedSong: GameSong?


    @State private var volume = 0.75


    @State private var audioPlayer: AVAudioPlayer?


    @State private var audioDelegate: AudioPlayerDelegate?


    @FocusState private var isKeyboardFocused: Bool



    var body: some View {

        ZStack {

            GameTheme.background

                .ignoresSafeArea()


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

        .frame(minWidth: 430, minHeight: 760)

        .focusable()

        .focused($isKeyboardFocused)

        .onKeyPress(keys: keyboardKeys, phases: .down, action: handleKeyPress)

        .task {

            isKeyboardFocused = true

            await viewModel.runGameLoop()
        }
    }



    private var gameView: some View {

        VStack(spacing: GameTheme.largeSpacing) {

            ScoreHeaderView(viewModel: viewModel, song: selectedSong)


            HealthBarView(viewModel: viewModel)


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

                .frame(maxWidth: 520, maxHeight: 760)


            GameControlsView(viewModel: viewModel) {

                stopAudio()
                viewModel.resetGame()
                currentScreen = .songSelection
            }
        }

        .padding(GameTheme.largePadding)
    }

    private var keyboardKeys: Set<KeyEquivalent> {

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

        if keyPress.key == .leftArrow || keyPress.key == KeyEquivalent("a") {
            viewModel.tap(column: 0)

        } else if keyPress.key == .upArrow || keyPress.key == KeyEquivalent("s") {
            viewModel.tap(column: 1)

        } else if keyPress.key == .downArrow || keyPress.key == KeyEquivalent("d") {
            viewModel.tap(column: 2)

        } else if keyPress.key == .rightArrow || keyPress.key == KeyEquivalent("f") {
            viewModel.tap(column: 3)
        }


        return .handled
    }
}

 

private enum AppScreen {
    case start
    case configuration
    case songSelection
    case game
}

#Preview {

    ContentView()
}

 
 
 
 
 
 
 
 
 

import SwiftUI

 

struct GameBoardView: View {

    let viewModel: GameViewModel


    let startRound: () -> Void

    var body: some View {

        GeometryReader { proxy in

            ZStack {

                laneBackground


                TargetLineView()
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height * GameViewModel.targetProgress
                    )


                ForEach(viewModel.tiles) { tile in
                    GameTileView()

                        .frame(width: proxy.size.width / CGFloat(GameViewModel.columnCount))

                        .position(
                            x: columnCenter(for: tile.column, width: proxy.size.width),
                            y: tileYPosition(for: tile.progress, height: proxy.size.height)
                        )
                }


                if viewModel.isPlaying == false {
                    GameOverlayView(viewModel: viewModel, startRound: startRound)
                }
            }

            .clipShape(RoundedRectangle(cornerRadius: GameTheme.cornerRadius))
        }

        .aspectRatio(0.58, contentMode: .fit)
    }

    private var laneBackground: some View {

        HStack(spacing: 0) {

            ForEach(0..<GameViewModel.columnCount, id: \.self) { column in
                Rectangle()

                    .fill(column.isMultiple(of: 2) ? GameTheme.panel : GameTheme.panel.opacity(0.55))

                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(.white.opacity(0.08))
                            .frame(width: 1)
                    }
            }
        }

        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.35))
                .frame(height: 2)
        }
    }

    private func columnCenter(for column: Int, width: Double) -> Double {

        let columnWidth = width / Double(GameViewModel.columnCount)


        return columnWidth * (Double(column) + 0.5)
    }

    private func tileYPosition(for progress: Double, height: Double) -> Double {

        let tileHeight = GameViewModel.tileHeight


        let start = -tileHeight / 2


        let end = height - tileHeight / 2


        return start + (end - start) * progress
    }
}

 

struct GameTileView: View {
    var body: some View {

        RoundedRectangle(cornerRadius: 12)

            .fill(GameTheme.tile)

            .shadow(color: GameTheme.tile.opacity(0.4), radius: 12)

            .padding(.horizontal, 5)

            .frame(height: GameViewModel.tileHeight)

            .accessibilityLabel("Falling tile")
    }
}

 

struct TargetLineView: View {
    var body: some View {

        HStack(spacing: 10) {
            Rectangle()

                .fill(GameTheme.accent)
                .frame(height: 3)

            Text("TAP HERE")

                .font(.caption)
                .bold()
                .foregroundStyle(GameTheme.accent)
                .fixedSize()

            Rectangle()

                .fill(GameTheme.accent)
                .frame(height: 3)
        }

        .padding(.horizontal, 12)

        .shadow(color: GameTheme.accent.opacity(0.8), radius: 8)
    }
}

 
 
 
 
 
 
 
 
 

import SwiftUI

 

struct GameControlsView: View {

    let viewModel: GameViewModel


    let exitToSongMenu: () -> Void

    var body: some View {

        HStack(spacing: 14) {

            Label("A / Left", systemImage: "arrow.left")


            Label("S / Up", systemImage: "arrow.up")


            Label("D / Down", systemImage: "arrow.down")


            Label("F / Right", systemImage: "arrow.right")
                .foregroundStyle(GameTheme.accent)


            Button {
                if viewModel.isPlaying {

                    viewModel.pauseGame()
                } else {

                    viewModel.startGame()
                }
            } label: {

                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .frame(minWidth: 48, minHeight: 48)
            }

            .buttonStyle(.borderedProminent)

            .tint(GameTheme.accent)

            .foregroundStyle(.black)

            .accessibilityLabel(viewModel.isPlaying ? "Pause game" : "Start game")


            Button("Exit", systemImage: "xmark", action: exitToSongMenu)
                .buttonStyle(.bordered)
                .tint(.white)
        }

        .font(.caption)

        .bold()

        .foregroundStyle(.white.secondary)
    }
}

 

struct HealthBarView: View {

    let viewModel: GameViewModel

    var body: some View {

        VStack(spacing: 4) {

            GeometryReader { proxy in
                ZStack(alignment: .leading) {

                    Capsule()
                        .fill(.white.opacity(0.2))


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

 

struct GameOverlayView: View {

    let viewModel: GameViewModel


    let startRound: () -> Void

    var body: some View {

        VStack(spacing: 12) {

            Image(systemName: viewModel.isWon ? "trophy.fill" : viewModel.isGameOver ? "flag.checkered" : "music.note")
                .font(.system(size: 38))
                .foregroundStyle(viewModel.isWon ? GameTheme.accent : viewModel.isGameOver ? GameTheme.danger : GameTheme.accent)


            Text(viewModel.isWon ? "You Win!" : viewModel.isGameOver ? "Game Over" : "Ready?")
                .font(.title)
                .bold()
                .foregroundStyle(.white)


            Text(viewModel.isWon ? "Song complete!\nScore: \(viewModel.score)" : viewModel.isGameOver ? "Score: \(viewModel.score)" : "Tap each tile before it reaches the bottom")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.secondary)


            Button(viewModel.isGameOver || viewModel.isWon ? "Play Again" : "Start Game", action: startRound)
                .buttonStyle(.borderedProminent)
                .tint(GameTheme.accent)
                .foregroundStyle(.black)
                .controlSize(.large)

                .keyboardShortcut(.return)
        }

        .padding(28)

        .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: GameTheme.cornerRadius))

        .padding(24)
    }
}

 

struct ScoreHeaderView: View {

    let viewModel: GameViewModel


    let song: GameSong?

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top) {

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

 

struct ScoreChip: View {

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

 

struct ScoreItem: View {

    let title: String


    let value: String

    var body: some View {

        VStack(spacing: 3) {

            Text(title)
                .font(.caption)
                .bold()
                .foregroundStyle(.white.secondary)


            Text(value)
                .font(.title3)
                .bold()
                .foregroundStyle(GameTheme.accent)
                .contentTransition(.numericText())
        }
    }
}

 
 
 
 
 
 
 
 
 

import SwiftUI

 

struct GameTile: Identifiable, Equatable {

    let id: UUID


    let column: Int


    var progress: Double

    init(column: Int, progress: Double = 0) {

        self.id = UUID()


        self.column = column


        self.progress = progress
    }
}

 

struct GameSong: Identifiable, Hashable {

    let id: String


    let title: String


    let subtitle: String


    let duration: String


    let audioFileName: String


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

 

enum GameTheme {

    static let background = Color(red: 0.04, green: 0.05, blue: 0.10)


    static let panel = Color.white.opacity(0.08)


    static let tile = Color(red: 0.12, green: 0.75, blue: 0.95)


    static let danger = Color(red: 1.0, green: 0.30, blue: 0.36)


    static let accent = Color(red: 0.97, green: 0.73, blue: 0.24)


    static let largeSpacing = 18.0


    static let largePadding = 24.0


    static let cornerRadius = 16.0
}

 
 
 
 
 
 
 
 
 

import Foundation
import Observation

@MainActor
@Observable
final class GameViewModel {



    static let columnCount = 4


    static let laneHeight = 760.0


    static let tileHeight = 70.0


    static let targetProgress = 0.72


    static let tapTolerancePixels = 30.0


    private(set) var tiles: [GameTile] = []


    private(set) var score = 0


    private(set) var bestScore = 0


    private(set) var streak = 0


    private(set) var successfulHits = 0


    private(set) var missedHits = 0


    var accuracy: Double {
        let totalHits = successfulHits + missedHits
        if totalHits == 0 {
            return 100
        }

        return Double(successfulHits) / Double(totalHits) * 100
    }


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


    private(set) var health = 12


    static let maximumHealth = 12


    private(set) var isPlaying = false


    private(set) var isGameOver = false


    private(set) var isWon = false


    private(set) var missedColumn: Int?


    private var lastUpdate = Date()


    private var spawnAccumulator = 0.0


    private var beatInterval = 0.5


    private var lanePattern: [Int] = [0, 1, 2, 3]


    private var nextLaneIndex = 0

    var speed: Double {

        0.72 / (beatInterval * 4)
    }

    var spawnInterval: Double {

        beatInterval
    }



    func runGameLoop() async {

        while !Task.isCancelled {

            try? await Task.sleep(for: .milliseconds(16))


            guard isPlaying else {
                lastUpdate = Date()
                continue
            }


            let now = Date()


            let elapsed = now.timeIntervalSince(lastUpdate)


            lastUpdate = now


            update(elapsed: elapsed)
        }
    }

    func startGame() {

        if isGameOver || isWon {
            resetGame()
        }


        isPlaying = true


        isGameOver = false
        isWon = false


        lastUpdate = Date()
    }

    func configureSong(songId: String) {

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

        isPlaying = false
    }

    func resetGame() {

        tiles = []


        score = 0


        streak = 0


        successfulHits = 0
        missedHits = 0


        health = Self.maximumHealth


        missedColumn = nil


        isGameOver = false
        isWon = false
        isPlaying = false


        spawnAccumulator = 0
        nextLaneIndex = 0


        lastUpdate = Date()
    }

    func winGame() {

        isPlaying = false


        guard isGameOver == false else {
            return
        }

        isWon = true
    }

    func tap(column: Int) {

        guard isPlaying, isGameOver == false, isWon == false else {
            return
        }


        guard let tileIndex = tappableTileIndex(in: column) else {

            loseHealth(amount: 1)
            return
        }


        let comboBonus = min(streak * 10, 500)
        score += 100 + comboBonus


        health = min(Self.maximumHealth, health + 1)


        streak += 1


        bestScore = max(bestScore, score)


        tiles.remove(at: tileIndex)
        successfulHits += 1
    }

    private func update(elapsed: Double) {

        var updatedTiles: [GameTile] = []


        for tile in tiles {

            var updatedTile = tile


            updatedTile.progress += elapsed * speed


            if updatedTile.progress >= 1 {
                handleMissedTile(updatedTile)
                return
            }


            updatedTiles.append(updatedTile)
        }


        tiles = updatedTiles


        spawnAccumulator += elapsed


        if spawnAccumulator >= spawnInterval {

            spawnAccumulator = 0


            spawnTile()
        }
    }

    private func spawnTile() {

        let column = lanePattern[nextLaneIndex]
        nextLaneIndex += 1
        if nextLaneIndex >= lanePattern.count {
            nextLaneIndex = 0
        }


        tiles.append(GameTile(column: column))
    }

    private func tappableTileIndex(in column: Int) -> Int? {

        var bestIndex: Int?


        let tapTolerance = Self.tapTolerancePixels / Self.laneHeight


        let tileProgressHeight = Self.tileHeight / Self.laneHeight


        for tileIndex in tiles.indices {
            let tile = tiles[tileIndex]


            let tileTop = tile.progress - tileProgressHeight


            let tileBottom = tile.progress


            let targetTop = Self.targetProgress - tapTolerance


            let targetBottom = Self.targetProgress + tapTolerance


            let touchesTarget = tileTop <= targetBottom && tileBottom >= targetTop


            if tile.column == column && touchesTarget {

                if let currentBestIndex = bestIndex {
                    if tiles[tileIndex].progress < tiles[currentBestIndex].progress {
                        bestIndex = tileIndex
                    }
                } else {

                    bestIndex = tileIndex
                }
            }
        }


        return bestIndex
    }

    private func handleMissedTile(_ tile: GameTile) {

        if let tileIndex = tiles.firstIndex(where: { existingTile in
            existingTile.id == tile.id
        }) {
            tiles.remove(at: tileIndex)
        }


        missedColumn = tile.column


        loseHealth(amount: 3)
    }

    private func loseHealth(amount: Int) {

        streak = 0
        missedHits += 1


        health = max(0, health - amount)


        guard health == 0 else {
            return
        }


        isPlaying = false


        isGameOver = true


        streak = 0
    }
}

 
 
 
 
 
 
 
 
 

import SwiftUI

 

struct StartScreenView: View {

    let showSongMenu: () -> Void


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

 

struct ConfigurationView: View {



    @Binding var volume: Double


    let goBack: () -> Void


    @State private var selectedTab = ConfigurationTab.settings



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

 

private enum ConfigurationTab {
    case settings
    case credits
}

 

struct SongSelectionView: View {

    let selectSong: (GameSong) -> Void


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

 
 
 
 
 
 
 
 
 

import SwiftUI

@main
struct TapTilesApp: App {


    var body: some Scene {

        WindowGroup {

            ContentView()
        }
    }
}
