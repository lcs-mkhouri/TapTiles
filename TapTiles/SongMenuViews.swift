//
//  SongMenuViews.swift
//  TapTiles
//

import SwiftUI

// MARK: - Start screen

struct StartScreenView: View {
    // Runs when the player chooses to open the song menu.
    let showSongMenu: () -> Void

    // Runs when the player chooses to open configuration.
    let showConfiguration: () -> Void

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

            Button("Configuration", systemImage: "gearshape", action: showConfiguration)
                .buttonStyle(.bordered)
                .tint(.white)
        }
        .padding(40)
        .frame(maxWidth: 430)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: GameTheme.cornerRadius))
        .padding(GameTheme.largePadding)
    }
}

// MARK: - Configuration

struct ConfigurationView: View {
    // Stores the selected volume level from 0 to 1.
    @Binding var volume: Double

    // Runs when the player returns to the starting screen.
    let goBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("CONFIGURATION")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Volume", systemImage: "speaker.wave.2")
                        .foregroundStyle(.white)

                    Spacer()

                    Text("\(Int(volume * 100))%")
                        .foregroundStyle(.white.secondary)
                }

                Slider(value: $volume, in: 0...1)
                    .tint(GameTheme.accent)
                    .accessibilityLabel("Volume")
                    .accessibilityValue("\(Int(volume * 100)) percent")
            }
            .frame(width: 300)

            Button("Back", systemImage: "chevron.left", action: goBack)
                .buttonStyle(.bordered)
                .tint(.white)
        }
        .padding(32)
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
