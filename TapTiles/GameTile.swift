//
//  GameTile.swift
//  TapTiles
//

import Foundation

struct GameTile: Identifiable, Equatable {
    // MARK: - Stored properties

    let id: UUID
    let column: Int
    var progress: Double
    var isTapped: Bool

    // MARK: - Initializer

    init(column: Int, progress: Double = 0, isTapped: Bool = false) {
        self.id = UUID()
        self.column = column
        self.progress = progress
        self.isTapped = isTapped
    }
}
