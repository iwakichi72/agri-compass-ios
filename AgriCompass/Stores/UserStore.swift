import Foundation
import Observation
import SwiftData

@Observable
final class UserStore {
    private let context: ModelContext

    private(set) var profile: UserProfile
    private(set) var activeCrops: [ActiveCropEntity] = []
    private(set) var harvestHistory: [HarvestRecordEntity] = []
    private(set) var achievements: [AchievementProgressEntity] = []
    private(set) var challenges: [ChallengeProgressEntity] = []

    init(context: ModelContext) {
        self.context = context
        self.profile = UserStore.fetchOrCreateProfile(context: context)
        reload()
    }

    private static func fetchOrCreateProfile(context: ModelContext) -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let p = UserProfile()
        context.insert(p)
        try? context.save()
        return p
    }

    func reload() {
        activeCrops = (try? context.fetch(FetchDescriptor<ActiveCropEntity>(
            sortBy: [SortDescriptor(\.plantedAt)]
        ))) ?? []
        harvestHistory = (try? context.fetch(FetchDescriptor<HarvestRecordEntity>(
            sortBy: [SortDescriptor(\.harvestedAt)]
        ))) ?? []
        achievements = (try? context.fetch(FetchDescriptor<AchievementProgressEntity>())) ?? []
        challenges = (try? context.fetch(FetchDescriptor<ChallengeProgressEntity>())) ?? []
    }

    private func save() {
        try? context.save()
        reload()
    }

    // MARK: - Profile

    func setRegion(_ region: Region) {
        profile.selectedRegion = region
        save()
    }

    func completeOnboarding() {
        profile.onboardingCompleted = true
        save()
    }

    // MARK: - Active crops

    @discardableResult
    func addActiveCrop(cropId: String, plantedAt: Date = Date(), nickname: String? = nil) -> ActiveCropEntity {
        let entity = ActiveCropEntity(cropId: cropId, plantedAt: plantedAt, nickname: nickname)
        context.insert(entity)
        save()
        return entity
    }

    func completeStep(instanceId: String, stepId: String) {
        guard let ac = activeCrops.first(where: { $0.instanceId == instanceId }) else { return }
        if ac.completedStepIds.contains(stepId) { return }
        ac.completedStepIds.append(stepId)
        ac.currentStepIndex += 1
        save()
    }

    func undoStep(instanceId: String, stepId: String, stepIndex: Int) {
        guard let ac = activeCrops.first(where: { $0.instanceId == instanceId }) else { return }
        ac.completedStepIds.removeAll(where: { $0 == stepId })
        ac.currentStepIndex = max(0, min(ac.currentStepIndex, stepIndex))
        save()
    }

    @discardableResult
    func markHarvested(instanceId: String, note: String? = nil) -> HarvestRecordEntity? {
        guard let ac = activeCrops.first(where: { $0.instanceId == instanceId }) else { return nil }
        let now = Date()
        ac.status = .harvested
        ac.harvestedAt = now
        let record = HarvestRecordEntity(
            instanceId: ac.instanceId,
            cropId: ac.cropId,
            plantedAt: ac.plantedAt,
            harvestedAt: now,
            note: note
        )
        context.insert(record)
        save()
        return record
    }

    func abandonCrop(instanceId: String) {
        guard let ac = activeCrops.first(where: { $0.instanceId == instanceId }) else { return }
        ac.status = .abandoned
        save()
    }

    // MARK: - Inventory

    func saveProfile() { save() }

    func toggleOwned(kind: InventoryKind, id: String) {
        switch kind {
        case .tool:
            if profile.inventory.tools[id] == true {
                profile.inventory.tools.removeValue(forKey: id)
            } else {
                profile.inventory.tools[id] = true
            }
        case .fertilizer:
            if profile.inventory.fertilizers[id] == true {
                profile.inventory.fertilizers.removeValue(forKey: id)
            } else {
                profile.inventory.fertilizers[id] = true
            }
        }
        save()
    }

    enum InventoryKind { case tool, fertilizer }

    // MARK: - Stats

    func incrementWeatherCheck() {
        profile.stats.weatherChecksCount += 1
        save()
    }

    @discardableResult
    func recordWhyRead(key: String) -> Bool {
        if profile.stats.whyReadIds.contains(key) { return false }
        profile.stats.whyReadIds.append(key)
        profile.stats.whyReadCount += 1
        save()
        return true
    }

    // MARK: - Achievements

    @discardableResult
    func unlockAchievement(_ id: String) -> Bool {
        if achievements.contains(where: { $0.achievementId == id }) { return false }
        let entity = AchievementProgressEntity(achievementId: id)
        context.insert(entity)
        save()
        return true
    }

    // MARK: - Challenges

    func joinChallenge(_ id: String) {
        if let existing = challenges.first(where: { $0.challengeId == id }) {
            if existing.joined { return }
            existing.joined = true
        } else {
            let entity = ChallengeProgressEntity(challengeId: id, joined: true)
            context.insert(entity)
        }
        save()
    }

    func updateChallengeProgress(id: String, goalId: String, value: Int) {
        let progress: ChallengeProgressEntity
        if let existing = challenges.first(where: { $0.challengeId == id }) {
            progress = existing
        } else {
            progress = ChallengeProgressEntity(challengeId: id)
            context.insert(progress)
        }
        progress.goalProgress[goalId] = value
        save()
    }

    func completeChallenge(_ id: String) {
        guard let progress = challenges.first(where: { $0.challengeId == id }),
              progress.completedAt == nil else { return }
        progress.completedAt = Date()
        save()
    }

    // MARK: - Visit / Streak

    func touchOnLaunch(toast: ToastCenter) {
        let result = StreakCalculator.compute(
            previous: .init(
                streakDays: profile.stats.streakDays,
                maxStreakDays: profile.stats.maxStreakDays,
                lastVisitDate: profile.stats.lastVisitDate
            )
        )
        profile.stats.streakDays = result.streakDays
        profile.stats.maxStreakDays = result.maxStreakDays
        profile.stats.lastVisitDate = result.lastVisitDate
        save()

        // Run achievement checks (e.g. streak milestones)
        runAchievementChecks(catalog: nil, toast: toast)
    }

    /// Re-evaluate all rules; surface any newly-unlocked achievements via toast.
    func runAchievementChecks(catalog: CatalogStore?, toast: ToastCenter?) {
        let resolver: (String) -> Crop? = { id in
            catalog?.crop(id: id)
        }
        let unlockedIds = AchievementEngine.evaluate(
            existing: Set(achievements.map(\.achievementId)),
            activeCrops: activeCrops,
            harvestHistory: harvestHistory,
            stats: profile.stats,
            cropResolver: resolver
        )
        for id in unlockedIds {
            unlockAchievement(id)
            if let toast, let achievement = catalog?.achievement(id: id) {
                toast.push(message: "実績解除: \(achievement.icon) \(achievement.name)")
            }
        }
    }

    /// Recompute and persist challenge progress values; toast on completion.
    func runChallengeChecks(catalog: CatalogStore?, toast: ToastCenter?) {
        guard let catalog else { return }
        let updates = ChallengeEngine.evaluate(
            allChallenges: catalog.challenges,
            activeCrops: activeCrops,
            harvestHistory: harvestHistory,
            stats: profile.stats,
            cropResolver: { catalog.crop(id: $0) }
        )
        for update in updates {
            updateChallengeProgress(id: update.id, goalId: update.goalId, value: update.value)
        }
        for ch in catalog.challenges {
            let allMet = ch.goals.allSatisfy { goal in
                let progress = challenges.first(where: { $0.challengeId == ch.id })?.goalProgress[goal.id] ?? 0
                return progress >= goal.target
            }
            let progress = challenges.first(where: { $0.challengeId == ch.id })
            if allMet, let progress, progress.completedAt == nil {
                completeChallenge(ch.id)
                toast?.push(message: "🏆 チャレンジ達成: \(ch.title)")
            }
        }
    }

    // MARK: - Reset

    func resetAll() {
        for ac in activeCrops { context.delete(ac) }
        for h in harvestHistory { context.delete(h) }
        for a in achievements { context.delete(a) }
        for c in challenges { context.delete(c) }
        context.delete(profile)
        try? context.save()
        profile = UserStore.fetchOrCreateProfile(context: context)
        reload()
    }
}
