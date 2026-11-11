//
//  ScoreItem.swift
//  TapTiles
//

import SwiftUI

struct ScoreItem: View {
    // MARK: - Stored properties

    let title: String
    let value: String

    // MARK: - Body

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption)
                .bold()
                .foregroundStyle(.white.secondary)

            Text(value)
                .font(.title3)
                .bold()
                .foregroundStyle(GameTheme.accent)
                .contentTransition(.numericText())
        }
    }
}
