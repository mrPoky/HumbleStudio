import Foundation

struct StudioMacWorkspaceContextSnapshot {
    let eyebrow: String?
    let title: String
    let subtitle: String
    let previousLabel: String?
}

struct StudioMacWorkspaceStatusSnapshot {
    let sourceSummary: String
    let sourceKind: String
    let recoveryReadiness: String
    let recoveryTone: String
    let parityLabel: String?
    let parityTone: StudioMacParityTone?
    let statusLevel: String
    let statusText: String
}

enum StudioMacParityTone {
    case exact
    case degraded
    case fallbackOnly

    var label: String {
        switch self {
        case .exact:
            return StudioStrings.parityExactLabel
        case .degraded:
            return StudioStrings.parityDegradedLabel
        case .fallbackOnly:
            return StudioStrings.parityFallbackLabel
        }
    }
}

enum StudioMacParityResolver {
    static func tone(for destination: StudioNativeDestination, document: StudioNativeDocument?) -> StudioMacParityTone {
        guard let document else {
            return destination == .legacyWeb ? .fallbackOnly : .degraded
        }

        switch destination {
        case .overview, .tokens, .icons:
            return .exact
        case .components, .views, .review, .navigation:
            return nativePreviewCoverageSummary(for: document).fallbackNeeded > 0 ? .degraded : .exact
        case .proposals:
            return .exact
        case .typography:
            return document.typography.contains(where: { nativeTypographyPreviewCoverage(for: $0) != .exact }) ? .degraded : .exact
        case .spacing:
            return (document.spacing + document.radius).contains(where: { nativeMetricPreviewCoverage(for: $0) != .exact }) ? .degraded : .exact
        case .legacyWeb:
            return .fallbackOnly
        }
    }
}

enum StudioMacWorkspaceContextResolver {
    static func resolve(
        selection: StudioNativeDestination?,
        selectionState: StudioNativeSelectionState,
        history: StudioNativeHistoryState,
        document: StudioNativeDocument?,
        pageTitle: String,
        breadcrumb: String
    ) -> StudioMacWorkspaceContextSnapshot {
        let activeSelection = selection ?? .overview
        let itemName = currentItemName(
            selection: activeSelection,
            selectionState: selectionState,
            document: document
        )
        let itemSummary = currentItemSummary(
            selection: activeSelection,
            selectionState: selectionState,
            document: document
        )

        if activeSelection == .legacyWeb {
            return StudioMacWorkspaceContextSnapshot(
                eyebrow: StudioStrings.webFallback,
                title: pageTitle,
                subtitle: breadcrumb,
                previousLabel: nil
            )
        }

        let previousLabel: String?
        if history.canNavigateBack, history.index > 0 {
            previousLabel = label(
                for: history.routes[history.index - 1],
                document: document
            )
        } else {
            previousLabel = nil
        }

        return StudioMacWorkspaceContextSnapshot(
            eyebrow: itemName == nil ? nil : activeSelection.title,
            title: itemName ?? activeSelection.title,
            subtitle: itemSummary ?? activeSelection.subtitle,
            previousLabel: previousLabel
        )
    }

    static func statusSnapshot(model: StudioShellModel, selection: StudioNativeDestination?) -> StudioMacWorkspaceStatusSnapshot {
        let activeSelection = selection ?? .overview
        let parityTone = StudioMacParityResolver.tone(for: activeSelection, document: model.nativeDocument)
        return StudioMacWorkspaceStatusSnapshot(
            sourceSummary: model.sourceSummary,
            sourceKind: model.sourceKindLabel,
            recoveryReadiness: model.recoveryReadinessLabel,
            recoveryTone: model.recoveryReadinessTone,
            parityLabel: activeSelection == .overview ? nil : parityTone.label,
            parityTone: activeSelection == .overview ? nil : parityTone,
            statusLevel: model.statusLevel,
            statusText: model.statusText
        )
    }

    static func label(for route: StudioNativeRoute, document: StudioNativeDocument?) -> String {
        guard let document else { return route.destination.title }
        switch route {
        case .overview, .review, .proposals, .legacyWeb:
            return route.destination.title
        case let .tokens(tokenSelection):
            switch tokenSelection {
            case let .color(id):
                return document.colors.first(where: { $0.id == id })?.name ?? route.destination.title
            case let .gradient(id):
                return document.gradients.first(where: { $0.id == id })?.name ?? route.destination.title
            case nil:
                return route.destination.title
            }
        case let .components(componentID):
            guard let componentID else { return route.destination.title }
            return document.components.first(where: { $0.id == componentID })?.name ?? route.destination.title
        case let .views(viewID):
            guard let viewID else { return route.destination.title }
            return document.views.first(where: { $0.id == viewID })?.name ?? route.destination.title
        case let .navigation(viewID):
            guard let viewID else { return route.destination.title }
            return document.views.first(where: { $0.id == viewID })?.name ?? route.destination.title
        case let .icons(iconID):
            guard let iconID else { return route.destination.title }
            return document.icons.first(where: { $0.id == iconID })?.name ?? route.destination.title
        case let .typography(typographyID):
            guard let typographyID else { return route.destination.title }
            return document.typography.first(where: { $0.id == typographyID })?.role ?? route.destination.title
        case let .spacing(metricSelection):
            switch metricSelection {
            case let .spacing(id):
                return document.spacing.first(where: { $0.id == id })?.name ?? route.destination.title
            case let .radius(id):
                return document.radius.first(where: { $0.id == id })?.name ?? route.destination.title
            case nil:
                return route.destination.title
            }
        }
    }

    private static func currentItemName(
        selection: StudioNativeDestination,
        selectionState: StudioNativeSelectionState,
        document: StudioNativeDocument?
    ) -> String? {
        guard let document else { return nil }
        switch selection {
        case .tokens:
            switch selectionState.tokenSelection {
            case let .color(id):
                return document.colors.first(where: { $0.id == id })?.name
            case let .gradient(id):
                return document.gradients.first(where: { $0.id == id })?.name
            case nil:
                return nil
            }
        case .components:
            return document.components.first(where: { $0.id == selectionState.componentID })?.name
        case .views:
            return document.views.first(where: { $0.id == selectionState.viewID })?.name
        case .icons:
            return document.icons.first(where: { $0.id == selectionState.iconID })?.name
        case .typography:
            return document.typography.first(where: { $0.id == selectionState.typographyID })?.role
        case .spacing:
            switch selectionState.metricSelection {
            case let .spacing(id):
                return document.spacing.first(where: { $0.id == id })?.name
            case let .radius(id):
                return document.radius.first(where: { $0.id == id })?.name
            case nil:
                return nil
            }
        case .navigation:
            return document.views.first(where: { $0.id == selectionState.navigationViewID })?.name
        case .overview, .review, .proposals, .legacyWeb:
            return nil
        }
    }

    private static func currentItemSummary(
        selection: StudioNativeDestination,
        selectionState: StudioNativeSelectionState,
        document: StudioNativeDocument?
    ) -> String? {
        guard let document else { return nil }
        switch selection {
        case .tokens:
            switch selectionState.tokenSelection {
            case let .color(id):
                guard let token = document.colors.first(where: { $0.id == id }) else { return nil }
                return "Color token · \(token.group)"
            case let .gradient(id):
                guard let token = document.gradients.first(where: { $0.id == id }) else { return nil }
                return "Gradient token · \(token.group)"
            case nil:
                return nil
            }
        case .components:
            guard let component = document.components.first(where: { $0.id == selectionState.componentID }) else { return nil }
            return component.summary.isEmpty ? StudioStrings.componentSummary(component.group) : component.summary
        case .views:
            guard let view = document.views.first(where: { $0.id == selectionState.viewID }) else { return nil }
            return view.summary.isEmpty ? StudioStrings.viewSummary(view.presentation) : view.summary
        case .icons:
            guard let icon = document.icons.first(where: { $0.id == selectionState.iconID }) else { return nil }
            return "Icon · \(icon.symbol)"
        case .typography:
            guard let token = document.typography.first(where: { $0.id == selectionState.typographyID }) else { return nil }
            return "\(Int(token.size)) pt · \(token.swiftUI)"
        case .spacing:
            switch selectionState.metricSelection {
            case let .spacing(id):
                guard let token = document.spacing.first(where: { $0.id == id }) else { return nil }
                return "Spacing · \(token.value)"
            case let .radius(id):
                guard let token = document.radius.first(where: { $0.id == id }) else { return nil }
                return "Corner radius · \(token.value)"
            case nil:
                return nil
            }
        case .navigation:
            guard let view = document.views.first(where: { $0.id == selectionState.navigationViewID }) else { return nil }
            return StudioStrings.navigationFlowSummary(outgoingCount: view.navigatesTo.count)
        case .overview, .review, .proposals, .legacyWeb:
            return nil
        }
    }
}
