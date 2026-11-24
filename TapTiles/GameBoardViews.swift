//
//  GameBoardViews.swift
//  TapTiles
//
//  Created by Michel Khouri on 2026-11-04.
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
