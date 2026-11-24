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
    // MARK: - Stored properties

    // Stores the selected volume level from 0 to 1.
    @Binding var volume: Double

    // Runs when the player returns to the starting screen.
    let goBack: () -> Void

    // Tracks whether the settings or credits tab is visible.
    @State private var selectedTab = ConfigurationTab.settings

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Text("CONFIGURATION")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)

            Picker("Configuration section", selection: $selectedTab) {
                Text("Settings").tag(ConfigurationTab.settings)
                Text("Credits").tag(ConfigurationTab.credits)
            }
            .pickerStyle(.segmented)
            .frame(width: 300)

            if selectedTab == .settings {
                settingsView
            } else {
                creditsView
            }

            Button("Back", systemImage: "chevron.left", action: goBack)
                .buttonStyle(.bordered)
                .tint(.white)
        }
        .padding(32)
        .frame(width: 430)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: GameTheme.cornerRadius))
        .padding(GameTheme.largePadding)
    }

    // MARK: - Computed properties

    private var settingsView: some View {
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
    }

    private var creditsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Audio Credits", systemImage: "person.2")
                .foregroundStyle(.white)

            ScrollView {
                Text(audioAttributions)
                    .font(.caption)
                    .textSelection(.enabled)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 300, height: 180)
            .padding(10)
            .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
            .accessibilityLabel("Audio credits")
        }
        .frame(width: 300)
    }

    private var audioAttributions: String {
        """
Expressions of the Mind (Piano Loop) by ShadyDave
https://freesound.org/s/325647/
License: Attribution NonCommercial 4.0

Rock Drums Swing 160 BPM.wav by carloseton
https://freesound.org/s/702006/
License: Creative Commons 0

Tragic Serenade by ViraMiller
https://freesound.org/s/748567/
License: Attribution 4.0

Progression1 Glass Style by wkalmar
https://freesound.org/s/732726/
License: Creative Commons 0

AI Statement: AI-assisted tools were used during the development of this app.
"""
    }
}

// MARK: - Configuration tab

private enum ConfigurationTab {
    case settings
    case credits
}

// MARK: - Song menu

struct SongSelectionView: View {
    // Runs when the player selects a song.
    let selectSong: (GameSong) -> Void

    // Runs when the player returns to the starting screen.
    let goBack: () -> Void

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

                                Text(song.duration)
                                    .font(.caption2)
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

            Button("Back", systemImage: "chevron.left", action: goBack)
                .buttonStyle(.bordered)
                .tint(.white)
        }
        .padding(28)
        .frame(maxWidth: 430)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: GameTheme.cornerRadius))
        .padding(GameTheme.largePadding)
    }
}
