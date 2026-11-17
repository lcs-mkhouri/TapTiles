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

    // Defines the number of lanes in the game.
    static let columnCount = 4

    // Defines the logical height used for movement calculations.
    static let laneHeight = 760.0

    // Defines how tall each tile appears on screen.
    static let tileHeight = 70.0

    // Places the target line 72% of the way down the board.
    static let targetProgress = 0.72

    // Allows a small amount of extra space around the target line.
    static let tapTolerancePixels = 30.0

    // Stores every tile currently falling on the board.
    private(set) var tiles: [GameTile] = []

    // Stores the player's score for the current round.
    private(set) var score = 0

    // Stores the highest score reached during this app session.
    private(set) var bestScore = 0

    // Counts successful taps in a row.
    private(set) var streak = 0

    // Stores the player's current health.
    private(set) var health = 12

    // Sets the maximum health for every round.
    static let maximumHealth = 12

    // Indicates whether the game is currently moving tiles.
    private(set) var isPlaying = false

    // Indicates whether a tile reached the bottom without being tapped.
    private(set) var isGameOver = false

    // Remembers which lane contained the tile that ended the game.
    private(set) var missedColumn: Int?

    // Records the time of the previous game-loop update.
    private var lastUpdate = Date()

    // Accumulates time until it is time to create another tile.
    private var spawnAccumulator = 0.0

    var speed: Double {
        // Starts tiles slowly and increases their speed as the score rises.
        min(0.72, 0.28 + Double(score) * 0.006)
    }

    var spawnInterval: Double {
        // Spawns tiles more often as the score rises, but never too quickly.
        max(0.38, 0.95 - Double(score) * 0.012)
    }

    // MARK: - Functions

    func runGameLoop() async {
        // Continues until SwiftUI cancels this view's task.
        while !Task.isCancelled {
            // Waits about 16 milliseconds, which is close to 60 updates per second.
            try? await Task.sleep(for: .milliseconds(16))

            // Resets the timer while the game is paused.
            guard isPlaying else {
                lastUpdate = Date()
                continue
            }

            // Gets the current time for this update.
            let now = Date()

            // Measures how much time passed since the previous update.
            let elapsed = now.timeIntervalSince(lastUpdate)

            // Saves this update's time for the next calculation.
            lastUpdate = now

            // Moves existing tiles and possibly creates a new tile.
            update(elapsed: elapsed)
        }
    }

    func startGame() {
        // A new game starts from zero after a game-over screen.
        if isGameOver {
            resetGame()
        }

        // Allows the game loop to move tiles.
        isPlaying = true

        // Clears the game-over state.
        isGameOver = false

        // Prevents a long paused duration from moving tiles immediately.
        lastUpdate = Date()
    }

    func pauseGame() {
        // Stops movement without deleting the current tiles.
        isPlaying = false
    }

    func resetGame() {
        // Removes all tiles from the board.
        tiles = []

        // Resets the round score.
        score = 0

        // Resets the consecutive-hit count.
        streak = 0

        // Restores the player's health to its maximum.
        health = Self.maximumHealth

        // Clears the lane that caused the previous game over.
        missedColumn = nil

        // Returns the game to its ready state.
        isGameOver = false
        isPlaying = false

        // Starts tile spawning from the beginning of its interval.
        spawnAccumulator = 0

        // Restarts time tracking from now.
        lastUpdate = Date()
    }

    func tap(column: Int) {
        // Ignores input when the game is paused or over.
        guard isPlaying, isGameOver == false else {
            return
        }

        // Finds a tile touching the target line in the selected lane.
        guard let tileIndex = tappableTileIndex(in: column) else {
            // Removes one health point when the player taps where no tile can be hit.
            loseHealth(amount: 1)
            return
        }

        // Awards one point for a successful tap.
        score += 1

        // Restores one health point after a successful tap without exceeding the cap.
        health = min(Self.maximumHealth, health + 1)

        // Increases the consecutive-hit count.
        streak += 1

        // Saves the highest score reached so far.
        bestScore = max(bestScore, score)

        // Removes the tile that was successfully tapped.
        tiles.remove(at: tileIndex)
    }

    private func update(elapsed: Double) {
        // Builds a new array containing the moved versions of the tiles.
        var updatedTiles: [GameTile] = []

        // Updates every tile one at a time.
        for tile in tiles {
            // Makes a copy so the tile's progress can be changed safely.
            var updatedTile = tile

            // Moves the tile according to elapsed time and current speed.
            updatedTile.progress += elapsed * speed

            // Ends the game if this tile has reached the bottom.
            if updatedTile.progress >= 1 {
                handleMissedTile(updatedTile)
                return
            }

            // Keeps the moved tile for the next frame.
            updatedTiles.append(updatedTile)
        }

        // Replaces the old tile list with the updated positions.
        tiles = updatedTiles

        // Adds this frame's time toward the next tile spawn.
        spawnAccumulator += elapsed

        // Creates a tile when enough time has accumulated.
        if spawnAccumulator >= spawnInterval {
            // Starts counting toward the following spawn.
            spawnAccumulator = 0

            // Adds a tile in an available lane.
            spawnTile()
        }
    }

    private func spawnTile() {
        // Collects the lanes that already contain a tile.
        var occupiedColumns: Set<Int> = []
        for tile in tiles {
            occupiedColumns.insert(tile.column)
        }

        // Builds a list of lanes that are currently empty.
        var availableColumns: [Int] = []
        for column in 0..<Self.columnCount {
            if occupiedColumns.contains(column) == false {
                availableColumns.append(column)
            }
        }

        // Prefers an empty lane, but always has a random fallback.
        let column = availableColumns.randomElement() ?? Int.random(in: 0..<Self.columnCount)

        // Adds a new tile at the top of the board.
        tiles.append(GameTile(column: column))
    }

    private func tappableTileIndex(in column: Int) -> Int? {
        // Stores the closest matching tile found so far.
        var bestIndex: Int?

        // Converts the forgiveness distance from pixels to progress units.
        let tapTolerance = Self.tapTolerancePixels / Self.laneHeight

        // Converts the tile's height from pixels to progress units.
        let tileProgressHeight = Self.tileHeight / Self.laneHeight

        // Checks every tile for overlap with the target line.
        for tileIndex in tiles.indices {
            let tile = tiles[tileIndex]

            // Calculates the tile's top edge in progress units.
            let tileTop = tile.progress - tileProgressHeight

            // The tile's progress represents its bottom edge.
            let tileBottom = tile.progress

            // Calculates the forgiving upper edge of the target area.
            let targetTop = Self.targetProgress - tapTolerance

            // Calculates the forgiving lower edge of the target area.
            let targetBottom = Self.targetProgress + tapTolerance

            // True means some part of the tile overlaps the target area.
            let touchesTarget = tileTop <= targetBottom && tileBottom >= targetTop

            // Only tiles in the selected lane can be tapped.
            if tile.column == column && touchesTarget {
                // Compares this tile with the closest matching tile already found.
                if let currentBestIndex = bestIndex {
                    if tiles[tileIndex].progress < tiles[currentBestIndex].progress {
                        bestIndex = tileIndex
                    }
                } else {
                    // Uses the first matching tile when no candidate exists yet.
                    bestIndex = tileIndex
                }
            }
        }

        // Returns the best tile to remove, or nil if no tile can be tapped.
        return bestIndex
    }

    private func handleMissedTile(_ tile: GameTile) {
        // Removes the missed tile so it cannot reduce health more than once.
        if let tileIndex = tiles.firstIndex(where: { existingTile in
            existingTile.id == tile.id
        }) {
            tiles.remove(at: tileIndex)
        }

        // Stores the lane that was missed for future UI use.
        missedColumn = tile.column

        // Removes four health points when a tile reaches the bottom.
        loseHealth(amount: 4)
    }

    private func loseHealth(amount: Int) {
        // Removes the requested health amount without allowing health to become negative.
        health = max(0, health - amount)

        // Keeps the game running while the player still has health remaining.
        guard health == 0 else {
            return
        }

        // Stops the game loop from moving more tiles.
        isPlaying = false

        // Shows the game-over overlay.
        isGameOver = true

        // Breaks the successful-tap streak.
        streak = 0
    }
}
