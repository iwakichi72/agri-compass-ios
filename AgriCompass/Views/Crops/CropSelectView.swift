import SwiftUI

struct CropSelectView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case quiz = "おすすめ診断"
        case catalog = "一覧から選ぶ"
        var id: String { rawValue }
    }
    @State private var mode: Mode = .quiz

    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            switch mode {
            case .quiz: QuizFlowView()
            case .catalog: CatalogListView()
            }
        }
        .background(Color.appCanvas)
        .navigationTitle("作物を選ぶ")
        .navigationBarTitleDisplayMode(.inline)
    }
}
