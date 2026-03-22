import SwiftUI

@Animatable
struct WPMView: View {
    var value: Double

    @AnimatableIgnored
    let scale: CGFloat

    let showResults: Bool

    var body: some View {
        Text(String(format: "%.0f", showResults ? value : 0))
            .font(.system(size: 64 * scale, design: .monospaced))
            .foregroundColor(AppTheme.accentGreen)
            .animation(.easeOut(duration: 20.0))
            .contentTransition(.numericText(value: value))
    }
}

struct ResultView: View {
    let scale: CGFloat
    let wpm: Double
    let accuracy: Double
    let wordsCompleted: Int
    let elapsedTime: TimeInterval

    @State private var showResults = false

    var body: some View {
        VStack(spacing: 16 * scale) {
            WPMView(value: wpm, scale: scale, showResults: showResults)

            Text("wpm")
                .font(.system(size: 20 * scale, design: .monospaced))
                .foregroundColor(AppTheme.subtleText)

            HStack(spacing: 32 * scale) {
                resultItem("accuracy", String(format: "%.0f%%", accuracy), scale: scale)
                resultItem("words", "\(wordsCompleted)", scale: scale)
                resultItem("time", formatDuration(elapsedTime), scale: scale)
            }
            .padding(.top, 8 * scale)

            HStack(spacing: 8) {
                Text("again")
                    .font(.system(size: 20 * scale, design: .monospaced))
                    .foregroundColor(AppTheme.accentGreen)
                Text("(space)")
                    .font(.system(size: 14 * scale, design: .monospaced))
                    .foregroundColor(AppTheme.subtleText)
            }
            .padding(.top, 24 * scale)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                showResults = true
            }
        }
        .onDisappear {
            showResults = false
        }
    }

    private func resultItem(_ label: String, _ value: String, scale: CGFloat) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20 * scale, design: .monospaced))
                .foregroundColor(AppTheme.correctText)
            Text(label)
                .font(.system(size: 14 * scale, design: .monospaced))
                .foregroundColor(AppTheme.subtleText)
        }
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let total = Int(t)
        let mins = total / 60
        let secs = total % 60
        return mins > 0 ? "\(mins):\(String(format: "%02d", secs))" : "\(secs)s"
    }
}

#Preview {
    ResultView(scale: 1.0, wpm: 72, accuracy: 95, wordsCompleted: 25, elapsedTime: 45)
        .frame(width: 800, height: 400)
        .background(AppTheme.background)
}
