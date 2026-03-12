// CarPlaySceneDelegate.swift
// Health Debug CarPlay integration — quick-log actions available from the dashboard while driving.
// Uses CPListTemplate (Information App style) — no audio/navigation entitlement needed.

import CarPlay
import SwiftData
import HealthDebugKit

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    var interfaceController: CPInterfaceController?
    private var context: ModelContext? {
        try? ModelContext(ModelContainerFactory.create())
    }

    // MARK: - Scene lifecycle

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        interfaceController.setRootTemplate(makeRootTemplate(), animated: false, completion: nil)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    // MARK: - Root Template

    private func makeRootTemplate() -> CPListTemplate {
        let sections = [
            hydrationSection(),
            focusSection(),
            caffeineSection(),
            statusSection(),
        ]
        let template = CPListTemplate(title: "Health Debug", sections: sections)
        template.emptyViewSubtitleVariants = ["Tap an action to log quickly while driving."]
        return template
    }

    // MARK: - Hydration Section

    private func hydrationSection() -> CPListSection {
        let total = HydrationManager.shared.todayTotal
        let goal = HydrationManager.shared.dailyGoal

        let headerItem = CPListItem(text: "Hydration", detailText: "\(total) / \(goal) ml today")
        headerItem.isEnabled = false

        let log150 = CPListItem(text: "+150ml Water", detailText: "Quick sip")
        log150.handler = { [weak self] _, completion in
            self?.logWater(ml: 150)
            completion()
        }

        let log250 = CPListItem(text: "+250ml Water", detailText: "Small glass")
        log250.handler = { [weak self] _, completion in
            self?.logWater(ml: 250)
            completion()
        }

        let log500 = CPListItem(text: "+500ml Water", detailText: "Large glass")
        log500.handler = { [weak self] _, completion in
            self?.logWater(ml: 500)
            completion()
        }

        return CPListSection(items: [headerItem, log150, log250, log500], header: "💧 Hydration", sectionIndexTitle: nil)
    }

    // MARK: - Focus Section

    private func focusSection() -> CPListSection {
        let timer = StandTimerManager.shared
        let completed = timer.todayCompleted
        let target = StandTimerManager.dailyTarget

        let statusItem = CPListItem(text: "Focus Sessions", detailText: "\(completed) / \(target) today")
        statusItem.isEnabled = false

        let actionItem: CPListItem
        if timer.phase == .idle {
            actionItem = CPListItem(text: "Start Focus Session", detailText: "Begin 90-min Pomodoro")
            actionItem.handler = { _, completion in
                StandTimerManager.shared.startCycle()
                completion()
            }
        } else if timer.phase == .work {
            let mins = Int(timer.secondsRemaining) / 60
            let secs = Int(timer.secondsRemaining) % 60
            actionItem = CPListItem(text: "Take a Break", detailText: "Focus: \(mins):\(String(format: "%02d", secs)) left")
            actionItem.handler = { _, completion in
                StandTimerManager.shared.startBreak()
                completion()
            }
        } else {
            let mins = Int(timer.secondsRemaining) / 60
            let secs = Int(timer.secondsRemaining) % 60
            actionItem = CPListItem(text: "Break in progress", detailText: "\(mins):\(String(format: "%02d", secs)) remaining")
            actionItem.isEnabled = false
        }

        return CPListSection(items: [statusItem, actionItem], header: "⏱ Focus", sectionIndexTitle: nil)
    }

    // MARK: - Caffeine Section

    private func caffeineSection() -> CPListSection {
        let mgr = CaffeineManager.shared

        let statusItem = CPListItem(text: "Caffeine", detailText: "\(mgr.todayCleanCount) clean · \(mgr.todaySugarCount) sugar")
        statusItem.isEnabled = false

        let espresso = CPListItem(text: "Log Espresso", detailText: "Clean caffeine ☕")
        espresso.handler = { [weak self] _, completion in
            self?.logCaffeine(.espresso)
            completion()
        }

        let coffee = CPListItem(text: "Log Black Coffee", detailText: "Clean caffeine")
        coffee.handler = { [weak self] _, completion in
            self?.logCaffeine(.blackCoffee)
            completion()
        }

        return CPListSection(items: [statusItem, espresso, coffee], header: "☕ Caffeine", sectionIndexTitle: nil)
    }

    // MARK: - Status Section

    private func statusSection() -> CPListSection {
        let health = HealthKitManager.shared
        let stepsText = health.stepCount >= 1000
            ? String(format: "%.1fk steps", health.stepCount / 1000)
            : "\(Int(health.stepCount)) steps"

        let steps = CPListItem(text: "Movement", detailText: stepsText + " today")
        steps.isEnabled = false

        let heart = CPListItem(text: "Heart Rate", detailText: "\(Int(health.heartRate)) BPM")
        heart.isEnabled = false

        let sleep = CPListItem(text: "Sleep", detailText: String(format: "%.1f hrs last night", health.sleepHours))
        sleep.isEnabled = false

        return CPListSection(items: [steps, heart, sleep], header: "📊 Status", sectionIndexTitle: nil)
    }

    // MARK: - Actions

    private func logWater(ml: Int) {
        guard let ctx = context else { return }
        HydrationManager.shared.logWater(ml, source: "carplay", context: ctx, profile: nil)
        refreshRoot()
    }

    private func logCaffeine(_ type: CaffeineType) {
        guard let ctx = context else { return }
        _ = CaffeineManager.shared.logCaffeine(type, context: ctx, profile: nil)
        refreshRoot()
    }

    private func refreshRoot() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, let ic = self.interfaceController else { return }
            ic.setRootTemplate(self.makeRootTemplate(), animated: false, completion: nil)
        }
    }
}
