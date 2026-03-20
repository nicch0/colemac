import Charts
import SwiftUI

struct LevelChart: View {
    let sessions: [Session]
    let animated: Bool

    private var maxWPM: Double {
        max((sessions.map(\.wpm).max() ?? 10) * 1.1, 20)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WPM Over Time")
                .font(AppTheme.monoFont)
                .foregroundColor(AppTheme.correctText)

            Chart {
                ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
                    LineMark(
                        x: .value("Session", index + 1),
                        y: .value("WPM", animated ? session.wpm : 0)
                    )
                    .foregroundStyle(AppTheme.accentGreen)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Session", index + 1),
                        y: .value("WPM", animated ? session.wpm : 0)
                    )
                    .foregroundStyle(AppTheme.accentGreen)
                    .symbolSize(30)
                }
            }
            .chartXAxisLabel("Session", alignment: .center)
            .chartYAxisLabel("WPM")
            .chartYScale(domain: 0...maxWPM)
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.4))
                    AxisValueLabel()
                        .font(AppTheme.monoFontSmall)
                        .foregroundStyle(AppTheme.subtleText)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.4))
                    AxisValueLabel()
                        .font(AppTheme.monoFontSmall)
                        .foregroundStyle(AppTheme.subtleText)
                }
            }
            .frame(height: 200)
        }
    }
}
