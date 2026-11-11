//
//  ContentView.swift
//  TapTiles
//
//  Created by Michel Khouri on 2026-11-10.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Stored properties

    @State private var viewModel = GameViewModel()
    @FocusState private var isKeyboardFocused: Bool

    // MARK: - Body

    var body: some View {
        ZStack {
            GameTheme.background
                .ignoresSafeArea()

            VStack(spacing: GameTheme.largeSpacing) {
                ScoreHeaderView(viewModel: viewModel)

                GameBoardView(viewModel: viewModel)
                    .frame(maxWidth: 520, maxHeight: 760)

                GameControlsView(viewModel: viewModel)
            }
            .padding(GameTheme.largePadding)
        }
        .frame(minWidth: 430, minHeight: 760)
        .focusable()
        .focused($isKeyboardFocused)
        .onKeyPress(keys: keyboardKeys, phases: .down, action: handleKeyPress)
        .task {
            isKeyboardFocused = true
            await viewModel.runGameLoop()
        }
    }

    // MARK: - Computed properties

    private var keyboardKeys: Set<KeyEquivalent> {
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
        if keyPress.key == .leftArrow || keyPress.key == KeyEquivalent("a") {
            viewModel.tap(column: 0)
        } else if keyPress.key == .upArrow || keyPress.key == KeyEquivalent("w") {
            viewModel.tap(column: 1)
        } else if keyPress.key == .downArrow || keyPress.key == KeyEquivalent("s") {
            viewModel.tap(column: 2)
        } else if keyPress.key == .rightArrow || keyPress.key == KeyEquivalent("d") {
            viewModel.tap(column: 3)
        }

        return .handled
    }
}

#Preview {
    ContentView()
}
