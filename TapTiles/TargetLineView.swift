//
//  TargetLineView.swift
//  TapTiles
//

import SwiftUI

struct TargetLineView: View {
    // MARK: - Body

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(GameTheme.accent)
                .frame(height: 3)

            Text("TAP HERE")
                .font(.caption)
                .bold()
                .foregroundStyle(GameTheme.accent)
                .fixedSize()

            Rectangle()
                .fill(GameTheme.accent)
                .frame(height: 3)
        }
        .padding(.horizontal, 12)
        .shadow(color: GameTheme.accent.opacity(0.8), radius: 8)
    }
}
