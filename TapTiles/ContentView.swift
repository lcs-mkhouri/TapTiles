//
//  ContentView.swift
//  TapTiles
//
//  Created by Michel Khouri on 2026-11-10.
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
