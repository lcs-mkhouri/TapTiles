//
//  GameSupport.swift
//  TapTiles
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

    // Provides the songs currently available in the menu.
    static let availableSongs = [
        GameSong(id: "neon-pulse", title: "Neon Pulse", subtitle: "2:48"),
        GameSong(id: "midnight-drive", title: "Midnight Drive", subtitle: "3:12"),
        GameSong(id: "pixel-rush", title: "Pixel Rush", subtitle: "1:56"),
        GameSong(id: "Infinite madness", title: "Infinte Madness", subtitle: "∞")
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
