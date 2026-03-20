import SwiftUI

struct ToolbarView: View {
    @Binding var showStats: Bool
    @Binding var showSettings: Bool
    @Binding var selectedLevel: Level
    @Binding var selectedMode: SessionMode
    @AppStorage("smoothCursor") private var smoothCursor = true
    @AppStorage("rememberLastLevel") private var rememberLastLevel = true

    var body: some View {
        HStack(spacing: 16) {
            Button("Colemac") {
                showStats = false
            }
            .buttonStyle(.plain)
            .font(AppTheme.monoFont)
            .foregroundColor(AppTheme.correctText)
            .withHover()

            Spacer()

            if !showStats {
                modeSelector

                Spacer()

                Picker("", selection: $selectedLevel) {
                    ForEach(Level.all) { level in
                        Text("Level \(level.id): \(level.name)").tag(level)
                    }
                }
                .pickerStyle(.menu)
                .foregroundColor(AppTheme.correctText)
                .frame(width: 180)
            }

            Button(showStats ? "Practice" : "Stats") {
                showStats.toggle()
            }
            .buttonStyle(.plain)
            .foregroundColor(AppTheme.accentGreen)
            .font(AppTheme.monoFontSmall)
            .withHover()

            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.subtleText)
            }
            .buttonStyle(.plain)
            .withHover()
            .popover(isPresented: $showSettings) {
                settings
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(AppTheme.surfaceBackground)
        .colorScheme(.dark)
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(AppTheme.monoFont)
                .foregroundColor(AppTheme.correctText)

            HStack {
                Text("Smooth cursor")
                Spacer()
                Toggle("", isOn: $smoothCursor)
                    .foregroundColor(AppTheme.correctText)
                    .toggleStyle(.switch)
            }
            .font(AppTheme.monoFontSmall)

            HStack {
                Text("Remember Last Level")
                Spacer()
                Toggle("", isOn: $rememberLastLevel)
                    .font(AppTheme.monoFontSmall)
                    .foregroundColor(AppTheme.correctText)
                    .toggleStyle(.switch)
            }
            .font(AppTheme.monoFontSmall)
        }
        .padding(16)
        .background(AppTheme.surfaceBackground)
    }

    private var modeSelector: some View {
        HStack(spacing: 2) {
            VStack(spacing: 2) {
                Text("Words")
                    .font(AppTheme.monoFontSmall.bold())
                    .foregroundColor(AppTheme.subtleText)

                modeGroup("words", [
                    .words(count: 10), .words(count: 25),
                    .words(count: 50), .words(count: 100),
                ])
            }

            Text("|")
                .foregroundColor(AppTheme.subtleText)
                .font(AppTheme.monoFontSmall.bold())
                .padding(.horizontal, 6)

            VStack(spacing: 2) {
                Text("Time")
                    .font(AppTheme.monoFontSmall)
                    .foregroundColor(AppTheme.subtleText)

                modeGroup("time", [
                    .time(seconds: 15), .time(seconds: 30),
                    .time(seconds: 60), .time(seconds: 120),
                ])
            }

            Text("|")
                .foregroundColor(AppTheme.subtleText)
                .font(AppTheme.monoFontSmall)
                .padding(.horizontal, 6)

            modeButton(.zen)
        }
    }

    private func modeGroup(_: String, _ modes: [SessionMode]) -> some View {
        HStack(spacing: 2) {
            ForEach(modes, id: \.label) { mode in
                modeButton(mode)
            }
        }
    }

    private func modeButton(_ mode: SessionMode) -> some View {
        Button(mode.label) {
            selectedMode = mode
        }
        .buttonStyle(.plain)
        .font(AppTheme.monoFontSmall)
        .foregroundColor(selectedMode == mode ? AppTheme.accentGreen : AppTheme.subtleText)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .withHover()
    }
}

#Preview {
    VStack {
        ToolbarView(
            showStats: .constant(false),
            showSettings: .constant(false),
            selectedLevel: .constant(Level.all[0]),
            selectedMode: .constant(.words(count: 50))
        )
        Spacer()
    }
    .background(AppTheme.background)
    .frame(width: 900, height: 500)
}
