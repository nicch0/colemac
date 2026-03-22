    private func resultsView(scale: CGFloat) -> some View {
        VStack(spacing: 16 * scale) {
            Text(String(format: "%.0f", showResults ? engine.state.wpm : 0))
                .font(.system(size: 64 * scale, design: .monospaced))
                .foregroundColor(AppTheme.accentGreen)
                .contentTransition(.numericText(value: showResults ? engine.state.wpm : 0))
            Text("wpm")
                .font(.system(size: 20 * scale, design: .monospaced))
                .foregroundColor(AppTheme.subtleText)

            HStack(spacing: 32 * scale) {
                resultItem("accuracy", String(format: "%.0f%%", engine.state.accuracy), scale: scale)
                resultItem("words", "\(engine.state.wordsCompleted)", scale: scale)
                resultItem("time", formatDuration(engine.state.elapsedTime), scale: scale)
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
            withAnimation(.easeOut(duration: 10.0)) {
                showResults = true
            }
        }
        .onDisappear {
            showResults = false
        }
    }
