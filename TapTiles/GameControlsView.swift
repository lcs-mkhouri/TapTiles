//
//  GameControlsView.swift
//  TapTiles
//

import SwiftUI

struct GameControlsView: View {
    // MARK: - Stored properties

    let viewModel: GameViewModel

    // MARK: - Body

    var body: some View {
        HStack(spacing: 14) {
            Label("A / Left", systemImage: "arrow.left")
            Label("W / Up", systemImage: "arrow.up")
            Label("S / Down", systemImage: "arrow.down")
            Label("D / Right", systemImage: "arrow.right")
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
        }
        .font(.caption)
        .bold()
        .foregroundStyle(.white.secondary)
    }
}
