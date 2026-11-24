//
//  GameHUDViews.swift
//  TapTiles
//
//  Created by Michel Khouri on 2026-11-04.
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
