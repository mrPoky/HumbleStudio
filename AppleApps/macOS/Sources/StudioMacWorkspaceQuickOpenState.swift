import Foundation

enum StudioMacWorkspaceQuickOpenState {
    static func currentKey(
        selection: StudioNativeDestination?,
        selectionState: StudioNativeSelectionState
    ) -> String? {
        switch selection {
        case .overview:
            return "page:overview"
        case .tokens:
            guard let selectedTokenSelection = selectionState.tokenSelection else { return "page:tokens" }
            return key(for: selectedTokenSelection)
        case .components:
            guard let selectedComponentID = selectionState.componentID else { return "page:components" }
            return "component:\(selectedComponentID)"
        case .views:
            guard let selectedViewID = selectionState.viewID else { return "page:views" }
            return "view:\(selectedViewID)"
        case .review:
            return "page:review"
        case .navigation:
            if let selectedNavigationViewID = selectionState.navigationViewID {
                return "view:\(selectedNavigationViewID)"
            }
            return "page:navigation"
        case .proposals:
            return "page:proposals"
        case .icons:
            guard let selectedIconID = selectionState.iconID else { return "page:icons" }
            return "icon:\(selectedIconID)"
        case .typography:
            guard let selectedTypographyID = selectionState.typographyID else { return "page:typography" }
            return "typography:\(selectedTypographyID)"
        case .spacing:
            guard let selectedMetricSelection = selectionState.metricSelection else { return "page:spacing" }
            return key(for: selectedMetricSelection)
        case .legacyWeb:
            return "page:legacyWeb"
        case nil:
            return nil
        }
    }

    static func recordRecentKey(_ key: String, in recentKeys: inout [String]) {
        recentKeys.removeAll(where: { $0 == key })
        recentKeys.insert(key, at: 0)
        recentKeys = Array(recentKeys.prefix(12))
    }

    static func key(for tokenSelection: StudioNativeTokenSelection) -> String {
        switch tokenSelection {
        case let .color(id):
            return "color:\(id)"
        case let .gradient(id):
            return "gradient:\(id)"
        }
    }

    static func key(for metricSelection: StudioNativeMetricSelection) -> String {
        switch metricSelection {
        case let .spacing(id):
            return "spacing:\(id)"
        case let .radius(id):
            return "radius:\(id)"
        }
    }
}
