//
//  SongMenuViews.swift
//  TapTiles
//

import SwiftUI

// MARK: - Start screen

struct StartScreenView: View {
    // Runs when the player chooses to open the song menu.
    let showSongMenu: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundStyle(GameTheme.accent)

            VStack(spacing: 8) {
                Text("TAP TILES")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)

                Text("Choose a song and keep the rhythm going.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.secondary)
            }

            Button("Choose Song", action: showSongMenu)
                .buttonStyle(.borderedProminent)
                .tint(GameTheme.accent)
                .foregroundStyle(.black)
                .controlSize(.large)
                .keyboardShortcut(.return)
        }
        .padding(40)
        .frame(maxWidth: 430)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: GameTheme.cornerRadius))
        .padding(GameTheme.largePadding)
    }
}

// MARK: - Song menu

struct SongSelectionView: View {
    // Runs when the player selects a song.
    let selectSong: (GameSong) -> Void

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Text("SELECT A SONG")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
            }

            VStack(spacing: 10) {
                ForEach(GameSong.availableSongs) { song in
                    Button {
                        selectSong(song)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "music.note")
                                .foregroundStyle(GameTheme.accent)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(song.title)
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Text(song.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.white.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.white.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: 430)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: GameTheme.cornerRadius))
        .padding(GameTheme.largePadding)
    }
}
