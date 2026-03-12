import Foundation
import Combine

// MARK: - Dashboard Layout Manager

/// Manages which 4 cards are pinned and the full ordering of all dashboard cards.
/// Persists configuration in UserDefaults under key "dashboardLayout".
@MainActor
final class DashboardLayout: ObservableObject {

    static let shared = DashboardLayout()

    // All valid card IDs in default order
    static let allCardIDs: [String] = [
        "dailyFlow", "steps", "energy", "heartRate", "sleep",
        "hydration", "standTimer", "nutrition", "caffeine", "shutdown", "weight"
    ]

    static let defaultPinned: [String] = ["steps", "energy", "heartRate", "sleep"]
    static let maxPinned = 4
    private static let udKeyPinned = "dashboardLayout_pinned"
    private static let udKeyOrder  = "dashboardLayout_order"

    /// Ordered list of pinned card IDs (max 4)
    @Published var pinnedIDs: [String] {
        didSet { persist() }
    }

    /// Full ordered list of all card IDs
    @Published var allCardOrder: [String] {
        didSet { persist() }
    }

    private init() {
        let savedPinned = UserDefaults.standard.stringArray(forKey: Self.udKeyPinned)
        let savedOrder  = UserDefaults.standard.stringArray(forKey: Self.udKeyOrder)

        // Validate saved pinned — keep only known IDs
        if let saved = savedPinned, !saved.isEmpty {
            pinnedIDs = saved.filter { Self.allCardIDs.contains($0) }.prefix(Self.maxPinned).map { $0 }
        } else {
            pinnedIDs = Self.defaultPinned
        }

        // Validate saved order — must contain all known IDs
        if let saved = savedOrder, Set(saved) == Set(Self.allCardIDs) {
            allCardOrder = saved
        } else {
            allCardOrder = Self.allCardIDs
        }
    }

    // MARK: - Pin / Unpin

    /// Pin a card. If already at max capacity, removes the least-recently-pinned (first in list).
    func pin(_ id: String) {
        guard Self.allCardIDs.contains(id), !pinnedIDs.contains(id) else { return }
        if pinnedIDs.count >= Self.maxPinned {
            pinnedIDs.removeFirst()
        }
        pinnedIDs.append(id)
    }

    func unpin(_ id: String) {
        pinnedIDs.removeAll { $0 == id }
    }

    func isPinned(_ id: String) -> Bool {
        pinnedIDs.contains(id)
    }

    func togglePin(_ id: String) {
        if isPinned(id) { unpin(id) } else { pin(id) }
    }

    // MARK: - Reorder

    /// Move cards in the full allCardOrder list using IndexSet (for List drag).
    func move(from source: IndexSet, to destination: Int) {
        allCardOrder.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Derived

    /// Cards that are NOT pinned, in allCardOrder order.
    var unpinnedCards: [String] {
        allCardOrder.filter { !pinnedIDs.contains($0) }
    }

    /// Pinned cards in the order they appear in allCardOrder (for consistent grid display).
    var pinnedOrdered: [String] {
        // Keep pinnedIDs order (insertion order = pin order)
        pinnedIDs
    }

    // MARK: - Persistence

    private func persist() {
        UserDefaults.standard.set(pinnedIDs, forKey: Self.udKeyPinned)
        UserDefaults.standard.set(allCardOrder, forKey: Self.udKeyOrder)
    }
}
