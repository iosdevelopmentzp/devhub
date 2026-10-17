import SwiftUI

struct LogLinesList: View {
    let stream: LogStream
    let lines: [LogLine]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(lines) { line in
                        LogLineRow(line: line)
                            .id(line.id)
                    }
                }
                .padding(.vertical, 4)
            }
            .onChange(of: lines.last?.id) {
                guard stream.isPaused == false, let last = lines.last else { return }
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

#Preview {
    LogLinesList(stream: LogStream(simulatorID: "A", name: "iPhone 17", process: "App", subsystem: "", level: .all), lines: [])
        .previewEnvironment()
}
