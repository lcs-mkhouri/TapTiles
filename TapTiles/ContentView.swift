//
//  ContentView.swift
//  TapTiles
//
//  Created by Michel Khouri on 2026-11-10.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Stored properties

    // Stores the game's state and keeps the view updated when that state changes.
    @State private var viewModel = GameViewModel()

    // Tracks whether this view currently receives keyboard input.
    @FocusState private var isKeyboardFocused: Bool

    // MARK: - Body

    var body: some View {
        // Places the background behind all of the game's content.
        ZStack {
            // Uses the shared game background color.
            GameTheme.background
                // Extends the background into the safe-area margins.
                .ignoresSafeArea()

            // Stacks the score, board, and controls vertically.
            VStack(spacing: GameTheme.largeSpacing) {
                // Shows the current score, best score, and streak.
                ScoreHeaderView(viewModel: viewModel)

                // Displays the falling tiles and target line.
                GameBoardView(viewModel: viewModel)
                    // Prevents the board from growing beyond a readable size.
                    .frame(maxWidth: 520, maxHeight: 760)

                // Shows the keyboard instructions and play/pause button.
                GameControlsView(viewModel: viewModel)
            }
            // Adds space around the main game layout.
            .padding(GameTheme.largePadding)
        }
        // Gives the game window a useful minimum size.
        .frame(minWidth: 430, minHeight: 760)
        // Allows the view to receive keyboard focus.
        .focusable()
        // Connects the focus state to the current view.
        .focused($isKeyboardFocused)
        // Sends matching keyboard presses to the handler below.
        .onKeyPress(keys: keyboardKeys, phases: .down, action: handleKeyPress)
        // Starts the game loop when this view appears.
        .task {
            // Automatically focuses the game so keyboard controls work immediately.
            isKeyboardFocused = true
            // Keeps updating the game until the view's task is cancelled.
            await viewModel.runGameLoop()
        }
    }

    // MARK: - Computed properties

    private var keyboardKeys: Set<KeyEquivalent> {
        // Lists every key that the game understands.
        [
            .leftArrow,
            .upArrow,
            .downArrow,
            .rightArrow,
            KeyEquivalent("a"),
            KeyEquivalent("w"),
            KeyEquivalent("s"),
            KeyEquivalent("d")
        ]
    }

    // MARK: - Functions

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        // Maps the left arrow and A key to the first lane.
        if keyPress.key == .leftArrow || keyPress.key == KeyEquivalent("a") {
            viewModel.tap(column: 0)
        // Maps the up arrow and W key to the second lane.
        } else if keyPress.key == .upArrow || keyPress.key == KeyEquivalent("w") {
            viewModel.tap(column: 1)
        // Maps the down arrow and S key to the third lane.
        } else if keyPress.key == .downArrow || keyPress.key == KeyEquivalent("s") {
            viewModel.tap(column: 2)
        // Maps the right arrow and D key to the fourth lane.
        } else if keyPress.key == .rightArrow || keyPress.key == KeyEquivalent("d") {
            viewModel.tap(column: 3)
        }

        // Prevents the key press from being handled by another control.
        return .handled
    }
}

#Preview {
    // Shows the main game screen in Xcode's preview canvas.
    ContentView()
}
