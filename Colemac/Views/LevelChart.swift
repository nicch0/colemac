import Charts
import SwiftUI

enum ChartMetric: String, CaseIterable {
    case wpm = "WPM"
    case accuracy = "Accuracy"
}

struct LevelChart: View {
    let sessions: [Session]
    let animated: Bool
    @State private var metric: ChartMetric = .wpm
    @State private var selectedIndex: Int?

    private var minY: Double {
        switch metric {
        case .wpm:
            let lowest = sessions.map(\.wpm).min() ?? 0
            return max(floor(lowest / 5) * 5 - 5, 0)
        case .accuracy:
            let lowest = sessions.map(\.accuracy).min() ?? 0
            return max(floor(lowest / 5) * 5 - 5, 0)
        }
    }

    private var maxY: Double {
        switch metric {
        case .wpm:
            return max((sessions.map(\.wpm).max() ?? 10) * 1.1, 20)
        case .accuracy:
            return 100
        }
    }

    private func value(for session: Session) -> Double {
        switch metric {
        case .wpm: return session.wpm
        case .accuracy: return session.accuracy
        }
    }

    private var chartColor: Color {
        metric == .wpm ? AppTheme.accentGreen : AppTheme.keyOrange
    }

    /// Linear regression: returns (startY, endY) for x=1...count
    private var trendLine: (start: Double, end: Double)? {
        let values = sessions.map { value(for: $0) }
        let n = Double(values.count)
        guard n >= 2 else { return nil }

        let xs = (1...values.count).map(Double.init)
        let sumX = xs.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(xs, values).reduce(0) { $0 + $1.0 * $1.1 }
        let sumX2 = xs.reduce(0) { $0 + $1 * $1 }

        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n

        return (intercept + slope, intercept + slope * n)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(metric.rawValue) Over Time")
                .font(AppTheme.monoFont)
                .foregroundColor(AppTheme.correctText)

            Chart {
                ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
                    LineMark(
                        x: .value("Session", index + 1),
                        y: .value(metric.rawValue, animated ? value(for: session) : 0)
                    )
                    .foregroundStyle(chartColor)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Session", index + 1),
                        y: .value(metric.rawValue, animated ? value(for: session) : 0)
                    )
                    .foregroundStyle(chartColor)
                    .symbolSize(30)
                }

                if let selected = selectedIndex,
                   selected >= 1, selected <= sessions.count {
                    let session = sessions[selected - 1]
                    RuleMark(x: .value("Session", selected))
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .annotation(position: .top, overflowResolution: .init(x: .fit, y: .disabled)) {
                            tooltipView(for: session)
                        }
                }

                if let trend = trendLine, animated {
                    LineMark(
                        x: .value("Session", 1),
                        y: .value(metric.rawValue, trend.start),
                        series: .value("Series", "Trend")
                    )
                    .foregroundStyle(chartColor.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))

                    LineMark(
                        x: .value("Session", sessions.count),
                        y: .value(metric.rawValue, trend.end),
                        series: .value("Series", "Trend")
                    )
                    .foregroundStyle(chartColor.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                }
            }
            .chartXAxisLabel {
                Text("Session")
                    .font(AppTheme.monoFontSmall)
                    .foregroundStyle(AppTheme.correctText)
            }
            .chartYAxisLabel {
                Text(metric.rawValue)
                    .font(AppTheme.monoFontSmall)
                    .foregroundStyle(AppTheme.correctText)
            }
            .chartYScale(domain: minY...maxY)
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
            .chartXSelection(value: $selectedIndex)

            Picker(selection: $metric) {
                ForEach(ChartMetric.allCases, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
            .colorScheme(.dark)
            .frame(width: 200)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    private static let tooltipDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private func tooltipView(for session: Session) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Self.tooltipDateFormatter.string(from: session.date))
                .foregroundColor(AppTheme.subtleText)

            HStack(spacing: 12) {
                Text("\(String(format: "%.0f", session.wpm)) wpm")
                    .foregroundColor(AppTheme.accentGreen)
                Text("\(String(format: "%.0f%%", session.accuracy)) acc")
                    .foregroundColor(AppTheme.keyOrange)
            }

            if let mode = session.mode {
                Text(mode)
                    .foregroundColor(AppTheme.subtleText)
            }
        }
        .font(AppTheme.monoFontSmall)
        .padding(8)
        .background(AppTheme.surfaceBackground)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    let sessions = (0 ..< 10).map { i in
        Session(
            date: Date().addingTimeInterval(Double(-10 + i) * 3600),
            level: 1,
            wpm: Double.random(in: 25 ... 60),
            accuracy: Double.random(in: 85 ... 99),
            duration: 30,
            totalKeystrokes: 100,
            correctKeystrokes: 90,
            wordsTyped: 25
        )
    }
    LevelChart(sessions: sessions, animated: true)
        .padding()
        .frame(width: 500, height: 300)
        .background(AppTheme.background)
}
