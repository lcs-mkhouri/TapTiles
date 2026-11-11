//
//  ScoreHeaderView.swift
//  TapTiles
//

import SwiftUI

struct ScoreHeaderView: View {
    // MARK: - Stored properties

    let viewModel: GameViewModel

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TAP TILES")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)

                Text("Keep the rhythm going")
                    .font(.subheadline)
                    .foregroundStyle(.white.secondary)
            }

            Spacer()

            HStack(spacing: 20) {
                ScoreItem(title: "SCORE", value: "\(viewModel.score)")
                ScoreItem(title: "BEST", value: "\(viewModel.bestScore)")
                ScoreItem(title: "STREAK", value: "\(viewModel.streak)")
            }
        }
    }
}
