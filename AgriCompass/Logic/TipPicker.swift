import Foundation

enum TipPicker {
    /// Pick a tip for a given day. Prefers tips matching the current season
    /// or the user's actively-growing crops, falls back to general tips.
    /// Deterministic per (day, activeCropIds) so the home tip is stable
    /// throughout the day.
    static func today(tips: [Tip],
                      activeCropIds: [String],
                      now: Date = Date()) -> Tip? {
        let pool = candidatePool(tips: tips, activeCropIds: activeCropIds, now: now)
        guard !pool.isEmpty else { return tips.first }
        let index = dayIndex(now: now, salt: activeCropIds.sorted().joined(separator: ","))
        return pool[index % pool.count]
    }

    static func candidatePool(tips: [Tip],
                              activeCropIds: [String],
                              now: Date) -> [Tip] {
        let season = Season.of(date: now)
        let cropSet = Set(activeCropIds)

        var preferred: [Tip] = []
        var seasonal: [Tip] = []
        var general: [Tip] = []
        for tip in tips {
            let cropMatch = (tip.cropTags ?? []).contains(where: { cropSet.contains($0) })
            let seasonMatch = (tip.seasons ?? []).contains(season)
            if cropMatch {
                preferred.append(tip)
            } else if seasonMatch {
                seasonal.append(tip)
            } else if tip.seasons == nil && tip.cropTags == nil {
                general.append(tip)
            }
        }
        // Mix preferred + seasonal first; if empty, fall back to general.
        let primary = preferred + seasonal
        return primary.isEmpty ? general + tips : primary + general
    }

    /// Day-of-year index, used to rotate tips deterministically.
    static func dayIndex(now: Date, salt: String) -> Int {
        let cal = DateUtils.calendar
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: now) ?? 1
        return dayOfYear + stableSaltOffset(salt)
    }

    private static func stableSaltOffset(_ salt: String) -> Int {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in salt.utf8 {
            hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
        return Int(hash % 31)
    }
}
