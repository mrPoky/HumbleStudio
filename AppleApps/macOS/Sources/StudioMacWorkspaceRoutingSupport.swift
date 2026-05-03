import Foundation

enum StudioNativeDestination: String, Hashable, CaseIterable {
    case overview
    case tokens
    case components
    case views
    case review
    case navigation
    case proposals
    case icons
    case typography
    case spacing
    case legacyWeb

    var title: String {
        StudioStrings.destinationTitle(self)
    }

    var subtitle: String {
        StudioStrings.destinationSubtitle(self)
    }

    var symbolName: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .tokens: return "paintpalette"
        case .components: return "square.grid.3x2"
        case .views: return "rectangle.on.rectangle"
        case .review: return "exclamationmark.circle"
        case .navigation: return "arrow.triangle.branch"
        case .proposals: return "doc.text.magnifyingglass"
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
    case proposals
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
        case .proposals: return .proposals
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

struct StudioMacWorkspaceRouteSession: Equatable {
    var selection: StudioNativeDestination? = .overview
    var selectionState = StudioNativeSelectionState()
    var recentQuickOpenKeys: [String] = []
    var history = StudioNativeHistoryState()
    var isApplyingRoute = false

    var currentQuickOpenKey: String? {
        StudioMacWorkspaceQuickOpenState.currentKey(
            selection: selection,
            selectionState: selectionState
        )
    }

    mutating func recordQuickOpenKey(_ key: String) {
        StudioMacWorkspaceQuickOpenState.recordRecentKey(key, in: &recentQuickOpenKeys)
    }

    mutating func navigateToDestination(
        _ destination: StudioNativeDestination,
        document: StudioNativeDocument?
    ) {
        recordQuickOpenKey("page:\(destination.rawValue)")
        applyRoute(
            StudioNativeRouteResolver.route(
                for: destination,
                state: selectionState,
                document: document
            ),
            document: document
        )
    }

    mutating func applyRoute(
        _ route: StudioNativeRoute,
        document: StudioNativeDocument?,
        addToHistory: Bool = true
    ) {
        StudioMacWorkspaceRouteActions.applyRoute(
            route,
            selection: &selection,
            selectionState: &selectionState,
            document: document,
            history: &history,
            isApplyingRoute: &isApplyingRoute,
            addToHistory: addToHistory
        )
    }

    mutating func navigateBack(
        document: StudioNativeDocument?,
        navigateLegacyBack: () -> Void
    ) {
        StudioMacWorkspaceRouteActions.navigateBack(
            selection: &selection,
            selectionState: &selectionState,
            document: document,
            history: &history,
            isApplyingRoute: &isApplyingRoute,
            navigateLegacyBack: navigateLegacyBack
        )
    }

    mutating func navigateForward(
        document: StudioNativeDocument?,
        navigateLegacyForward: () -> Void
    ) {
        StudioMacWorkspaceRouteActions.navigateForward(
            selection: &selection,
            selectionState: &selectionState,
            document: document,
            history: &history,
            isApplyingRoute: &isApplyingRoute,
            navigateLegacyForward: navigateLegacyForward
        )
    }

    mutating func syncRouteFromState(document: StudioNativeDocument?) {
        StudioMacWorkspaceRouteActions.syncRouteFromState(
            selection: selection,
            selectionState: selectionState,
            document: document,
            history: &history,
            isApplyingRoute: isApplyingRoute
        )
    }
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

enum StudioNativeRouteController {
    static func syncRoute(
        selection: StudioNativeDestination?,
        selectionState: StudioNativeSelectionState,
        document: StudioNativeDocument?,
        history: inout StudioNativeHistoryState,
        isApplyingRoute: Bool
    ) {
        guard !isApplyingRoute else { return }
        history.record(
            StudioNativeRouteResolver.currentRoute(
                for: selection,
                state: selectionState,
                document: document
            )
        )
    }

    static func navigateBack(
        selection: StudioNativeDestination?,
        history: inout StudioNativeHistoryState
    ) -> StudioNativeRoute? {
        guard selection != .legacyWeb else { return nil }
        return history.stepBackward()
    }

    static func navigateForward(
        selection: StudioNativeDestination?,
        history: inout StudioNativeHistoryState
    ) -> StudioNativeRoute? {
        guard selection != .legacyWeb else { return nil }
        return history.stepForward()
    }

    static func apply(
        route: StudioNativeRoute,
        selection: inout StudioNativeDestination?,
        selectionState: inout StudioNativeSelectionState,
        document: StudioNativeDocument?,
        history: inout StudioNativeHistoryState,
        isApplyingRoute: inout Bool,
        addToHistory: Bool = true
    ) {
        isApplyingRoute = true

        switch route {
        case .overview:
            selection = .overview
        case let .tokens(tokenSelection):
            selectionState.tokenSelection =
                tokenSelection
                ?? StudioNativeRouteResolver.resolvedTokenSelection(
                    state: selectionState,
                    document: document
                )
            selection = .tokens
        case let .components(componentID):
            selectionState.componentID =
                componentID
                ?? StudioNativeRouteResolver.resolvedComponentID(
                    state: selectionState,
                    document: document
                )
            selection = .components
        case let .views(viewID):
            let resolvedViewID =
                viewID
                ?? StudioNativeRouteResolver.resolvedViewID(
                    state: selectionState,
                    document: document
                )
            selectionState.viewID = resolvedViewID
            selectionState.navigationViewID = resolvedViewID
            selection = .views
        case .review:
            selection = .review
        case let .navigation(viewID):
            selectionState.navigationViewID =
                viewID
                ?? StudioNativeRouteResolver.resolvedNavigationViewID(
                    state: selectionState,
                    document: document
                )
            selection = .navigation
        case .proposals:
            selection = .proposals
        case let .icons(iconID):
            selectionState.iconID =
                iconID
                ?? StudioNativeRouteResolver.resolvedIconID(
                    state: selectionState,
                    document: document
                )
            selection = .icons
        case let .typography(typographyID):
            selectionState.typographyID =
                typographyID
                ?? StudioNativeRouteResolver.resolvedTypographyID(
                    state: selectionState,
                    document: document
                )
            selection = .typography
        case let .spacing(metricSelection):
            selectionState.metricSelection =
                metricSelection
                ?? StudioNativeRouteResolver.resolvedMetricSelection(
                    state: selectionState,
                    document: document
                )
            selection = .spacing
        case .legacyWeb:
            selection = .legacyWeb
        }

        isApplyingRoute = false

        if addToHistory {
            history.record(
                StudioNativeRouteResolver.currentRoute(
                    for: selection,
                    state: selectionState,
                    document: document
                )
            )
        }
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
        case .proposals:
            return .proposals
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

enum StudioMacWorkspaceRouteActions {
    static func canNavigateBack(
        selection: StudioNativeDestination?,
        webCanGoBack: Bool,
        history: StudioNativeHistoryState
    ) -> Bool {
        selection == .legacyWeb ? webCanGoBack : history.canNavigateBack
    }

    static func canNavigateForward(
        selection: StudioNativeDestination?,
        webCanGoForward: Bool,
        history: StudioNativeHistoryState
    ) -> Bool {
        selection == .legacyWeb ? webCanGoForward : history.canNavigateForward
    }

    static func navigateBack(
        selection: inout StudioNativeDestination?,
        selectionState: inout StudioNativeSelectionState,
        document: StudioNativeDocument?,
        history: inout StudioNativeHistoryState,
        isApplyingRoute: inout Bool,
        navigateLegacyBack: () -> Void
    ) {
        if selection == .legacyWeb {
            navigateLegacyBack()
            return
        }
        guard let route = StudioNativeRouteController.navigateBack(
            selection: selection,
            history: &history
        ) else { return }
        StudioNativeRouteController.apply(
            route: route,
            selection: &selection,
            selectionState: &selectionState,
            document: document,
            history: &history,
            isApplyingRoute: &isApplyingRoute,
            addToHistory: false
        )
    }

    static func navigateForward(
        selection: inout StudioNativeDestination?,
        selectionState: inout StudioNativeSelectionState,
        document: StudioNativeDocument?,
        history: inout StudioNativeHistoryState,
        isApplyingRoute: inout Bool,
        navigateLegacyForward: () -> Void
    ) {
        if selection == .legacyWeb {
            navigateLegacyForward()
            return
        }
        guard let route = StudioNativeRouteController.navigateForward(
            selection: selection,
            history: &history
        ) else { return }
        StudioNativeRouteController.apply(
            route: route,
            selection: &selection,
            selectionState: &selectionState,
            document: document,
            history: &history,
            isApplyingRoute: &isApplyingRoute,
            addToHistory: false
        )
    }

    static func syncRouteFromState(
        selection: StudioNativeDestination?,
        selectionState: StudioNativeSelectionState,
        document: StudioNativeDocument?,
        history: inout StudioNativeHistoryState,
        isApplyingRoute: Bool
    ) {
        StudioNativeRouteController.syncRoute(
            selection: selection,
            selectionState: selectionState,
            document: document,
            history: &history,
            isApplyingRoute: isApplyingRoute
        )
    }

    static func applyRoute(
        _ route: StudioNativeRoute,
        selection: inout StudioNativeDestination?,
        selectionState: inout StudioNativeSelectionState,
        document: StudioNativeDocument?,
        history: inout StudioNativeHistoryState,
        isApplyingRoute: inout Bool,
        addToHistory: Bool
    ) {
        StudioNativeRouteController.apply(
            route: route,
            selection: &selection,
            selectionState: &selectionState,
            document: document,
            history: &history,
            isApplyingRoute: &isApplyingRoute,
            addToHistory: addToHistory
        )
    }
}
