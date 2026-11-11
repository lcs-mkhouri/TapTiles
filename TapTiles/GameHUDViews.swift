//
//  GameHUDViews.swift
//  TapTiles
//

import SwiftUI

// MARK: - Game controls

struct GameControlsView: View {
    // Reads game state so the button can show play or pause.
    let viewModel: GameViewModel

    var body: some View {
        // Places keyboard instructions and the play/pause button in one row.
        HStack(spacing: 14) {
            // Displays the first lane's keyboard controls.
            Label("A / Left", systemImage: "arrow.left")

            // Displays the second lane's keyboard controls.
            Label("W / Up", systemImage: "arrow.up")

            // Displays the third lane's keyboard controls.
            Label("S / Down", systemImage: "arrow.down")

            // Displays and highlights the fourth lane's keyboard controls.
            Label("D / Right", systemImage: "arrow.right")
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
        }
        // Uses compact text for the control row.
        .font(.caption)
        // Makes the labels easier to read.
        .bold()
        // Uses a muted color for secondary controls.
        .foregroundStyle(.white.secondary)
    }
}

// MARK: - Game overlay

struct GameOverlayView: View {
    // Reads game state to display the correct overlay message.
    let viewModel: GameViewModel

    var body: some View {
        // Stacks the icon, message, score, and action button.
        VStack(spacing: 12) {
            // Shows a different symbol before and after game over.
            Image(systemName: viewModel.isGameOver ? "flag.checkered" : "music.note")
                .font(.system(size: 38))
                .foregroundStyle(viewModel.isGameOver ? GameTheme.danger : GameTheme.accent)

            // Changes the heading based on whether a round has ended.
            Text(viewModel.isGameOver ? "Game Over" : "Ready?")
                .font(.title)
                .bold()
                .foregroundStyle(.white)

            // Shows the score after game over or instructions before starting.
            Text(viewModel.isGameOver ? "Score: \(viewModel.score)" : "Tap each tile before it reaches the bottom")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.secondary)

            // Starts a new round or restarts the previous round.
            Button(viewModel.isGameOver ? "Play Again" : "Start Game", action: viewModel.startGame)
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

    var body: some View {
        // Places the title on the left and scores on the right.
        HStack {
            // Groups the title and subtitle vertically.
            VStack(alignment: .leading, spacing: 4) {
                // Displays the game title.
                Text("TAP TILES")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)

                // Displays a short description below the title.
                Text("Keep the rhythm going")
                    .font(.subheadline)
                    .foregroundStyle(.white.secondary)
            }

            // Pushes the score items to the trailing edge.
            Spacer()

            // Places the score values beside one another.
            HStack(spacing: 20) {
                ScoreItem(title: "SCORE", value: "\(viewModel.score)")
                ScoreItem(title: "BEST", value: "\(viewModel.bestScore)")
                ScoreItem(title: "STREAK", value: "\(viewModel.streak)")
            }
        }
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
