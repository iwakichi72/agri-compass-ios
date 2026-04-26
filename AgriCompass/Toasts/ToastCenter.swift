import Foundation
import Observation

@Observable
final class ToastCenter {
    struct ToastItem: Identifiable, Hashable {
        let id = UUID()
        let message: String
    }

    var items: [ToastItem] = []

    func push(message: String) {
        let item = ToastItem(message: message)
        items.append(item)
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            self?.items.removeAll(where: { $0.id == item.id })
        }
    }
}
