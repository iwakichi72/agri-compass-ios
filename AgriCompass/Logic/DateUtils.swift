import Foundation

enum DateUtils {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone.current
        return c
    }()

    static func startOfDay(_ d: Date) -> Date {
        calendar.startOfDay(for: d)
    }

    static func diffDays(_ a: Date, _ b: Date) -> Int {
        let da = startOfDay(a)
        let db = startOfDay(b)
        return calendar.dateComponents([.day], from: da, to: db).day ?? 0
    }

    static func addDays(_ d: Date, _ days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: d) ?? d
    }

    static func addMonths(_ d: Date, _ months: Int) -> Date {
        calendar.date(byAdding: .month, value: months, to: d) ?? d
    }

    static func startOfMonth(_ d: Date = Date()) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: d)
        return calendar.date(from: comps).map(startOfDay) ?? startOfDay(d)
    }

    static func monthGridDates(_ d: Date = Date()) -> [Date] {
        let start = startOfMonth(d)
        let lastDay = addDays(addMonths(start, 1), -1)
        let gridStart = startOfWeek(start)
        let gridEnd = addDays(startOfWeek(lastDay), 6)
        let count = diffDays(gridStart, gridEnd) + 1
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    static func formatMD(_ d: Date) -> String {
        let m = calendar.component(.month, from: d)
        let day = calendar.component(.day, from: d)
        return "\(m)/\(day)"
    }

    static func formatYM(_ d: Date) -> String {
        let y = calendar.component(.year, from: d)
        let m = calendar.component(.month, from: d)
        return "\(y)年\(m)月"
    }

    static func formatYMD(_ d: Date) -> String {
        let y = calendar.component(.year, from: d)
        let m = calendar.component(.month, from: d)
        let day = calendar.component(.day, from: d)
        return "\(y)/\(m)/\(day)"
    }

    static func dateOnlyISO(_ d: Date) -> String {
        let y = calendar.component(.year, from: d)
        let m = calendar.component(.month, from: d)
        let day = calendar.component(.day, from: d)
        return String(format: "%04d-%02d-%02d", y, m, day)
    }

    static func formatWeekday(_ d: Date) -> String {
        let labels = ["日", "月", "火", "水", "木", "金", "土"]
        let w = calendar.component(.weekday, from: d) - 1
        return labels[w]
    }

    /// Monday-based start of week.
    static func startOfWeek(_ d: Date = Date()) -> Date {
        let n = startOfDay(d)
        let weekday = calendar.component(.weekday, from: n) // Sun=1..Sat=7
        // Convert to Mon=0..Sun=6
        let zeroBased = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -zeroBased, to: n) ?? n
    }

    static func weekDates(_ d: Date = Date()) -> [Date] {
        let start = startOfWeek(d)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    static func twoWeekDates(_ d: Date = Date()) -> [Date] {
        let start = startOfWeek(d)
        return (0..<14).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    static func isSameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    static func isSameMonth(_ a: Date, _ b: Date) -> Bool {
        let ac = calendar.dateComponents([.year, .month], from: a)
        let bc = calendar.dateComponents([.year, .month], from: b)
        return ac.year == bc.year && ac.month == bc.month
    }
}
