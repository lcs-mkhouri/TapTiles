//
//  GameViewModel.swift
//  TapTiles
//

import Foundation
import Observation

@MainActor
@Observable
final class GameViewModel {
    // MARK: - Stored properties

    static let columnCount = 4
    static let laneHeight = 760.0
    static let tileHeight = 70.0
    static let targetProgress = 0.72
    static let tapTolerancePixels = 30.0

    private(set) var tiles: [GameTile] = []
    private(set) var score = 0
    private(set) var bestScore = 0
    private(set) var streak = 0
    private(set) var isPlaying = false
    private(set) var isGameOver = false
    private(set) var missedColumn: Int?

    private var lastUpdate = Date()
    private var spawnAccumulator = 0.0

    var speed: Double {
        min(0.72, 0.28 + Double(score) * 0.006)
    }

    var spawnInterval: Double {
        max(0.38, 0.95 - Double(score) * 0.012)
    }

    // MARK: - Functions

    func runGameLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(16))
            guard isPlaying else {
                lastUpdate = Date()
                continue
            }

            let now = Date()
            let elapsed = now.timeIntervalSince(lastUpdate)
            lastUpdate = now
            update(elapsed: elapsed)
        }
    }

    func startGame() {
        if isGameOver {
            resetGame()
        }

        isPlaying = true
        isGameOver = false
        lastUpdate = Date()
    }

    func pauseGame() {
        isPlaying = false
    }

    func resetGame() {
        tiles = []
        score = 0
        streak = 0
        missedColumn = nil
        isGameOver = false
        isPlaying = false
        spawnAccumulator = 0
        lastUpdate = Date()
    }

    func tap(column: Int) {
        guard isPlaying, isGameOver == false else {
            return
        }

        guard let tileIndex = tappableTileIndex(in: column) else {
            return
        }

        tiles[tileIndex].isTapped = true
        score += 1
        streak += 1
        bestScore = max(bestScore, score)

        tiles.remove(at: tileIndex)
    }

    private func update(elapsed: Double) {
        var updatedTiles: [GameTile] = []

        for tile in tiles {
            var updatedTile = tile
            updatedTile.progress += elapsed * speed

            if updatedTile.progress >= 1 {
                endGame(missedColumn: updatedTile.column)
                return
            }

            updatedTiles.append(updatedTile)
        }

        tiles = updatedTiles
        spawnAccumulator += elapsed

        if spawnAccumulator >= spawnInterval {
            spawnAccumulator = 0
            spawnTile()
        }
    }

    private func spawnTile() {
        var occupiedColumns: Set<Int> = []
        for tile in tiles {
            occupiedColumns.insert(tile.column)
        }

        var availableColumns: [Int] = []
        for column in 0..<Self.columnCount {
            if occupiedColumns.contains(column) == false {
                availableColumns.append(column)
            }
        }

        let column = availableColumns.randomElement() ?? Int.random(in: 0..<Self.columnCount)
        tiles.append(GameTile(column: column))
    }

    private func tappableTileIndex(in column: Int) -> Int? {
        var candidateIndices: [Int] = []
        let tapTolerance = Self.tapTolerancePixels / Self.laneHeight
        let tileProgressHeight = Self.tileHeight / Self.laneHeight

        for tileIndex in tiles.indices {
            let tile = tiles[tileIndex]
            let tileTop = tile.progress - tileProgressHeight
            let tileBottom = tile.progress
            let targetTop = Self.targetProgress - tapTolerance
            let targetBottom = Self.targetProgress + tapTolerance
            let touchesTarget = tileTop <= targetBottom && tileBottom >= targetTop

            if tile.column == column && touchesTarget {
                candidateIndices.append(tileIndex)
            }
        }

        guard var bestIndex = candidateIndices.first else {
            return nil
        }

        for candidateIndex in candidateIndices.dropFirst() {
            if tiles[candidateIndex].progress < tiles[bestIndex].progress {
                bestIndex = candidateIndex
            }
        }

        return bestIndex
    }

    private func endGame(missedColumn: Int) {
        isPlaying = false
        isGameOver = true
        self.missedColumn = missedColumn
        streak = 0
    }
}
