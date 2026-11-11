//
//  GameBoardView.swift
//  TapTiles
//

import SwiftUI

struct GameBoardView: View {
    // MARK: - Stored properties

    let viewModel: GameViewModel

    // MARK: - Body

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
                    GameTileView(tile: tile)
                        .frame(width: proxy.size.width / CGFloat(GameViewModel.columnCount))
                        .position(
                            x: columnCenter(for: tile.column, width: proxy.size.width),
                            y: tileYPosition(for: tile.progress, height: proxy.size.height)
                        )
                }

                if viewModel.isPlaying == false {
                    GameOverlayView(viewModel: viewModel)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.cornerRadius))
        }
        .aspectRatio(0.58, contentMode: .fit)
    }

    // MARK: - Views

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

    // MARK: - Functions

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
