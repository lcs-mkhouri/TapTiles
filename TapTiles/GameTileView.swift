//
//  GameTileView.swift
//  TapTiles
//

import SwiftUI

struct GameTileView: View {
    // MARK: - Stored properties

    let tile: GameTile

    // MARK: - Body

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(tile.isTapped ? GameTheme.tileActive : GameTheme.tile)
            .shadow(color: GameTheme.tile.opacity(0.4), radius: 12)
            .padding(.horizontal, 5)
            .frame(height: GameViewModel.tileHeight)
            .accessibilityLabel("Falling tile")
    }
}
