//
//  GameOverlayView.swift
//  TapTiles
//

import SwiftUI

struct GameOverlayView: View {
    // MARK: - Stored properties

    let viewModel: GameViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.isGameOver ? "flag.checkered" : "music.note")
                .font(.system(size: 38))
                .foregroundStyle(viewModel.isGameOver ? GameTheme.danger : GameTheme.accent)

            Text(viewModel.isGameOver ? "Game Over" : "Ready?")
                .font(.title)
                .bold()
                .foregroundStyle(.white)

            Text(viewModel.isGameOver ? "Score: \(viewModel.score)" : "Tap each tile before it reaches the bottom")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.secondary)

            Button(viewModel.isGameOver ? "Play Again" : "Start Game", action: viewModel.startGame)
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
