import Foundation

struct Tool: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let emoji: String
    let category: ToolCategory
    let description: String
    let buyHint: String?
}
