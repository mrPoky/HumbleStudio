import Foundation

enum StudioNativeDestination: String, Hashable, CaseIterable {
    case overview
    case tokens
    case components
    case views
    case review
    case navigation
    case icons
    case typography
    case spacing
    case legacyWeb

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .tokens: return "Tokens"
        case .components: return "Components"
        case .views: return "Views"
        case .review: return "Review Queue"
        case .navigation: return "Navigation Map"
        case .icons: return "Icons"
        case .typography: return "Typography"
        case .spacing: return "Spacing & Radius"
        case .legacyWeb: return "Legacy Web Inspector"
        }
    }

    var subtitle: String {
        switch self {
        case .overview:
            return "Native foundations workspace for imported design exports."
        case .tokens:
            return "Colors and gradients rendered directly in SwiftUI."
        case .components:
            return "Snapshot-first component catalog rendered natively."
        case .views:
            return "Screen catalog with snapshot and flow truth, rendered natively."
        case .review:
            return "Native queue for components and views whose exported truth still needs attention."
        case .navigation:
            return "Native flow map over exported navigation edges and root routing."
        case .icons:
            return "Native icon catalog sourced from the imported bundle."
        case .typography:
            return "Type styles decoded from the export contract."
        case .spacing:
            return "Padding and corner radius tokens rendered natively."
        case .legacyWeb:
            return "Fallback web inspector for any parity gaps that are not native yet."
        }
    }

    var symbolName: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .tokens: return "paintpalette"
        case .components: return "square.grid.3x2"
        case .views: return "rectangle.on.rectangle"
        case .review: return "exclamationmark.circle"
        case .navigation: return "arrow.triangle.branch"
        case .icons: return "app.gift"
        case .typography: return "textformat"
        case .spacing: return "square.on.square"
        case .legacyWeb: return "globe"
        }
    }
}

enum StudioNativeRoute: Equatable {
    case overview
    case tokens(StudioNativeTokenSelection?)
    case components(String?)
    case views(String?)
    case review
    case navigation(String?)
    case icons(String?)
    case typography(String?)
    case spacing(StudioNativeMetricSelection?)
    case legacyWeb

    var destination: StudioNativeDestination {
        switch self {
        case .overview: return .overview
        case .tokens: return .tokens
        case .components: return .components
        case .views: return .views
        case .review: return .review
        case .navigation: return .navigation
        case .icons: return .icons
        case .typography: return .typography
        case .spacing: return .spacing
        case .legacyWeb: return .legacyWeb
        }
    }
}

struct StudioNativeSelectionState: Equatable {
    var tokenSelection: StudioNativeTokenSelection?
    var iconID: String?
    var typographyID: String?
    var metricSelection: StudioNativeMetricSelection?
    var componentID: String?
    var viewID: String?
    var navigationViewID: String?
}

struct StudioNativeHistoryState: Equatable {
    var routes: [StudioNativeRoute] = [.overview]
    var index = 0

    var canNavigateBack: Bool { index > 0 }
    var canNavigateForward: Bool { index < routes.count - 1 }

    mutating func record(_ route: StudioNativeRoute) {
        if routes.isEmpty {
            routes = [route]
            index = 0
            return
        }

        if routes[index] == route {
            return
        }

        if index < routes.count - 1 {
            routes = Array(routes.prefix(index + 1))
        }

        routes.append(route)
        index = routes.count - 1
    }

    mutating func stepBackward() -> StudioNativeRoute? {
        guard canNavigateBack else { return nil }
        index -= 1
        return routes[index]
    }

    mutating func stepForward() -> StudioNativeRoute? {
        guard canNavigateForward else { return nil }
        index += 1
        return routes[index]
    }
}

enum StudioNativeRouteResolver {
    static func route(
        for destination: StudioNativeDestination,
        state: StudioNativeSelectionState,
        document: StudioNativeDocument?
    ) -> StudioNativeRoute {
        switch destination {
        case .overview:
            return .overview
        case .tokens:
            return .tokens(resolvedTokenSelection(state: state, document: document))
        case .components:
            return .components(resolvedComponentID(state: state, document: document))
        case .views:
            return .views(resolvedViewID(state: state, document: document))
        case .review:
            return .review
        case .navigation:
            return .navigation(resolvedNavigationViewID(state: state, document: document))
        case .icons:
            return .icons(resolvedIconID(state: state, document: document))
        case .typography:
            return .typography(resolvedTypographyID(state: state, document: document))
        case .spacing:
            return .spacing(resolvedMetricSelection(state: state, document: document))
        case .legacyWeb:
            return .legacyWeb
        }
    }

    static func currentRoute(
        for destination: StudioNativeDestination?,
        state: StudioNativeSelectionState,
        document: StudioNativeDocument?
    ) -> StudioNativeRoute {
        route(for: destination ?? .overview, state: state, document: document)
    }

    static func resolvedTokenSelection(state: StudioNativeSelectionState, document: StudioNativeDocument?) -> StudioNativeTokenSelection? {
        if let tokenSelection = state.tokenSelection {
            return tokenSelection
        }
        if let firstColor = document?.colors.first {
            return .color(firstColor.id)
        }
        if let firstGradient = document?.gradients.first {
            return .gradient(firstGradient.id)
        }
        return nil
    }

    static func resolvedComponentID(state: StudioNativeSelectionState, document: StudioNativeDocument?) -> String? {
        state.componentID ?? document?.components.first?.id
    }

    static func resolvedViewID(state: StudioNativeSelectionState, document: StudioNativeDocument?) -> String? {
        state.viewID ?? document?.views.first?.id
    }

    static func resolvedNavigationViewID(state: StudioNativeSelectionState, document: StudioNativeDocument?) -> String? {
        state.navigationViewID ?? document?.navigationRootID ?? document?.views.first?.id
    }

    static func resolvedIconID(state: StudioNativeSelectionState, document: StudioNativeDocument?) -> String? {
        state.iconID ?? document?.icons.first?.id
    }

    static func resolvedTypographyID(state: StudioNativeSelectionState, document: StudioNativeDocument?) -> String? {
        state.typographyID ?? document?.typography.first?.id
    }

    static func resolvedMetricSelection(state: StudioNativeSelectionState, document: StudioNativeDocument?) -> StudioNativeMetricSelection? {
        if let metricSelection = state.metricSelection {
            return metricSelection
        }
        if let firstSpacing = document?.spacing.first {
            return .spacing(firstSpacing.id)
        }
        if let firstRadius = document?.radius.first {
            return .radius(firstRadius.id)
        }
        return nil
    }
}
