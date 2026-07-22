import SwiftUI

enum StudioPreviewOrientation: String, CaseIterable, Identifiable {
    case portrait
    case landscape

    var id: String { rawValue }

    var label: String { StudioStrings.previewOrientationLabel(self) }
}

enum StudioPreviewSizeClass: String {
    case compact
    case regular

    var label: String { StudioStrings.previewSizeClassLabel(self) }
}

enum StudioPreviewPresentationMode: String, CaseIterable, Identifiable {
    case push = "Push"
    case sheet = "Sheet"
    case fullScreenCover = "Full Screen"

    var id: String { rawValue }

    var label: String { StudioStrings.previewPresentationModeLabel(self) }
}

enum StudioPreviewNavigationChrome: String, CaseIterable, Identifiable {
    case none = "None"
    case navigationBar = "Navigation"
    case tabBar = "Tab Bar"
    case both = "Both"

    var id: String { rawValue }

    var label: String { StudioStrings.previewNavigationChromeLabel(self) }
}

enum StudioPreviewNavigationDepth: String, CaseIterable, Identifiable {
    case root = "Root"
    case detail = "Detail"
    case deep = "Deep Link"

    var id: String { rawValue }

    var label: String { StudioStrings.previewNavigationDepthLabel(self) }
}

enum StudioPreviewModalLayering: String, CaseIterable, Identifiable {
    case inline = "Inline"
    case elevated = "Elevated"
    case blocking = "Blocking"

    var id: String { rawValue }

    var label: String { StudioStrings.previewModalLayeringLabel(self) }
}

enum StudioPreviewStackContext: String, CaseIterable, Identifiable {
    case single = "Single Screen"
    case stacked = "Stacked Flow"
    case branched = "Branched Flow"

    var id: String { rawValue }

    var summary: String {
        StudioStrings.previewStackContextSummary(self)
    }

    var breadcrumbLabels: [String] {
        StudioStrings.previewBreadcrumbLabels(self)
    }
}

enum StudioPreviewCoverageLevel: String, CaseIterable, Identifiable {
    case exact = "Exact"
    case contractDriven = "Contract-driven"
    case fallbackNeeded = "Fallback needed"

    var id: String { rawValue }

    var label: String { StudioStrings.previewCoverageLabel(self) }

    var color: Color {
        switch self {
        case .exact:
            return .green
        case .contractDriven:
            return .orange
        case .fallbackNeeded:
            return .red
        }
    }

    var summary: String {
        StudioStrings.previewCoverageSummary(self)
    }
}

enum StudioPreviewLayoutMode: String, CaseIterable, Identifiable {
    case regular = "Fit"
    case focus = "Focus"

    var id: String { rawValue }

    var label: String { StudioStrings.previewLayoutModeLabel(self) }
}

struct StudioPreviewDevice: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let portraitSize: CGSize
    let landscapeSize: CGSize
    let cornerRadius: CGFloat
    let bezelPadding: CGFloat
    let portraitSafeArea: StudioPreviewSafeAreaInsets
    let landscapeSafeArea: StudioPreviewSafeAreaInsets
    let notes: String

    func canvasSize(for orientation: StudioPreviewOrientation) -> CGSize {
        orientation == .portrait ? portraitSize : landscapeSize
    }

    func safeAreaInsets(for orientation: StudioPreviewOrientation) -> StudioPreviewSafeAreaInsets {
        orientation == .portrait ? portraitSafeArea : landscapeSafeArea
    }

    func sizeClasses(for orientation: StudioPreviewOrientation) -> (horizontal: StudioPreviewSizeClass, vertical: StudioPreviewSizeClass) {
        if id.hasPrefix("ipad") {
            return (.regular, .regular)
        }

        switch orientation {
        case .portrait:
            return (.compact, .regular)
        case .landscape:
            return (.regular, .compact)
        }
    }
}

struct StudioPreviewSafeAreaInsets: Equatable, Hashable {
    let top: CGFloat
    let bottom: CGFloat
    let horizontal: CGFloat
}

struct StudioPreviewChromeGeometry: Equatable {
    let safeArea: StudioPreviewSafeAreaInsets
    let topContentInset: CGFloat
    let bottomContentInset: CGFloat
    let horizontalContentInset: CGFloat
    let navigationBarHeight: CGFloat
    let navigationContentHeight: CGFloat
    let tabBarHeight: CGFloat
    let tabContentHeight: CGFloat
    let fullScreenDismissTopInset: CGFloat
    let fullScreenDismissHorizontalInset: CGFloat
    let sheetChromeTopInset: CGFloat
    let sheetChromeHorizontalInset: CGFloat

    init(configuration: StudioPreviewConfiguration) {
        let safeArea = configuration.device.safeAreaInsets(for: configuration.orientation)
        let showsNavigation = configuration.navigationChrome == .navigationBar || configuration.navigationChrome == .both
        let showsTab = configuration.navigationChrome == .tabBar || configuration.navigationChrome == .both
        let showsFullScreenDismiss = configuration.presentationMode == .fullScreenCover && !showsNavigation
        let edgeInset = max(14, safeArea.horizontal + 14)
        let navigationContentHeight: CGFloat = 52
        let tabContentHeight: CGFloat = 58

        self.safeArea = safeArea
        self.navigationContentHeight = navigationContentHeight
        self.tabContentHeight = tabContentHeight
        self.navigationBarHeight = showsNavigation ? safeArea.top + navigationContentHeight : 0
        self.tabBarHeight = showsTab ? tabContentHeight + safeArea.bottom : 0
        self.horizontalContentInset = edgeInset
        self.topContentInset = showsNavigation
            ? safeArea.top + navigationContentHeight + 6
            : safeArea.top + (showsFullScreenDismiss ? 52 : 14)
        self.bottomContentInset = showsTab
            ? tabContentHeight + safeArea.bottom + 12
            : safeArea.bottom + 14
        self.fullScreenDismissTopInset = safeArea.top + 14
        self.fullScreenDismissHorizontalInset = edgeInset
        self.sheetChromeTopInset = max(10, min(24, safeArea.top + 8))
        self.sheetChromeHorizontalInset = 12 + min(safeArea.horizontal, 20)
    }
}

enum StudioPreviewCatalog {
    static let devices: [StudioPreviewDevice] = [
        StudioPreviewDevice(
            id: "iphone-compact",
            name: StudioStrings.previewDeviceName("iphone-compact"),
            portraitSize: CGSize(width: 393, height: 852),
            landscapeSize: CGSize(width: 852, height: 393),
            cornerRadius: 44,
            bezelPadding: 18,
            portraitSafeArea: StudioPreviewSafeAreaInsets(top: 59, bottom: 34, horizontal: 0),
            landscapeSafeArea: StudioPreviewSafeAreaInsets(top: 0, bottom: 21, horizontal: 59),
            notes: StudioStrings.previewDeviceNotes("iphone-compact")
        ),
        StudioPreviewDevice(
            id: "iphone-plus",
            name: StudioStrings.previewDeviceName("iphone-plus"),
            portraitSize: CGSize(width: 430, height: 932),
            landscapeSize: CGSize(width: 932, height: 430),
            cornerRadius: 48,
            bezelPadding: 20,
            portraitSafeArea: StudioPreviewSafeAreaInsets(top: 59, bottom: 34, horizontal: 0),
            landscapeSafeArea: StudioPreviewSafeAreaInsets(top: 0, bottom: 21, horizontal: 59),
            notes: StudioStrings.previewDeviceNotes("iphone-plus")
        ),
        StudioPreviewDevice(
            id: "ipad-portrait",
            name: StudioStrings.previewDeviceName("ipad-portrait"),
            portraitSize: CGSize(width: 834, height: 1194),
            landscapeSize: CGSize(width: 1194, height: 834),
            cornerRadius: 36,
            bezelPadding: 18,
            portraitSafeArea: StudioPreviewSafeAreaInsets(top: 24, bottom: 20, horizontal: 0),
            landscapeSafeArea: StudioPreviewSafeAreaInsets(top: 24, bottom: 20, horizontal: 0),
            notes: StudioStrings.previewDeviceNotes("ipad-portrait")
        )
    ]

    static let defaultDevice = devices[0]
}

struct StudioPreviewConfiguration: Equatable {
    var device: StudioPreviewDevice = StudioPreviewCatalog.defaultDevice
    var orientation: StudioPreviewOrientation = .portrait
    var presentationMode: StudioPreviewPresentationMode = .push
    var navigationChrome: StudioPreviewNavigationChrome = .navigationBar
    var navigationDepth: StudioPreviewNavigationDepth = .detail
    var modalLayering: StudioPreviewModalLayering = .inline
    var stackContext: StudioPreviewStackContext = .single
    var coverageLevel: StudioPreviewCoverageLevel = .contractDriven
    var showSafeAreas = true
    var showDeviceFrame = true
    var breadcrumbTrail: [String] = []
    var currentStep: Int?
    var totalSteps: Int?
    var modalDepth: Int = 1
    var contractNote: String?

    var sizeClasses: (horizontal: StudioPreviewSizeClass, vertical: StudioPreviewSizeClass) {
        device.sizeClasses(for: orientation)
    }

    var safeAreaInsets: StudioPreviewSafeAreaInsets {
        device.safeAreaInsets(for: orientation)
    }

    var chromeGeometry: StudioPreviewChromeGeometry {
        StudioPreviewChromeGeometry(configuration: self)
    }

    var resolvedBreadcrumbTrail: [String] {
        let cleaned = breadcrumbTrail
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return cleaned.isEmpty ? stackContext.breadcrumbLabels : cleaned
    }

    var resolvedCurrentStep: Int? {
        guard let currentStep, currentStep > 0 else { return nil }
        return currentStep
    }

    var resolvedTotalSteps: Int? {
        if let totalSteps, totalSteps > 0 {
            if let resolvedCurrentStep {
                return max(totalSteps, resolvedCurrentStep)
            }
            return totalSteps
        }
        return resolvedCurrentStep
    }

    var resolvedModalDepth: Int {
        max(modalDepth, 1)
    }

    var contractSummary: String {
        StudioStrings.previewContractSummary(
            deviceName: device.name,
            orientation: orientation,
            presentationMode: presentationMode,
            navigationChrome: navigationChrome,
            navigationDepth: navigationDepth,
            stackContext: stackContext
        )
    }

    var behaviorSummary: String {
        StudioStrings.previewBehaviorSummary(
            presentationMode: presentationMode,
            navigationChrome: navigationChrome,
            navigationDepth: navigationDepth,
            modalLayering: modalLayering,
            stackContext: stackContext
        )
    }

    var breadcrumbSummary: String {
        StudioStrings.previewBreadcrumbTrailSummary(resolvedBreadcrumbTrail)
    }

    var flowProgressSummary: String {
        StudioStrings.previewFlowProgressSummary(
            currentStep: resolvedCurrentStep,
            totalSteps: resolvedTotalSteps
        )
    }

    var modalContextSummary: String {
        StudioStrings.previewModalContextSummary(
            depth: resolvedModalDepth,
            presentationMode: presentationMode,
            layering: modalLayering
        )
    }

    var contractNoteSummary: String {
        let trimmed = contractNote?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? StudioStrings.previewContractDerivedFromModel : trimmed
    }

    static func viewDefault(presentation: String) -> StudioPreviewConfiguration {
        var configuration = StudioPreviewConfiguration()
        let normalized = presentation.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalized.contains("sheet") || normalized.contains("modal") {
            configuration.presentationMode = .sheet
            configuration.navigationChrome = .none
            configuration.navigationDepth = .root
            configuration.modalLayering = .elevated
            configuration.stackContext = .stacked
        } else if normalized.contains("full") {
            configuration.presentationMode = .fullScreenCover
            configuration.navigationChrome = .none
            configuration.navigationDepth = .root
            configuration.modalLayering = .blocking
            configuration.stackContext = .branched
        } else if normalized.contains("tab") {
            configuration.navigationChrome = .tabBar
            configuration.navigationDepth = .root
            configuration.modalLayering = .inline
            configuration.stackContext = .branched
        } else {
            configuration.navigationChrome = .navigationBar
            configuration.navigationDepth = .detail
            configuration.modalLayering = .inline
            configuration.stackContext = .stacked
        }

        return configuration
    }
}

struct StudioPreviewControls: View {
    @Binding var configuration: StudioPreviewConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker(StudioStrings.previewDeviceLabel, selection: $configuration.device) {
                ForEach(StudioPreviewCatalog.devices) { device in
                    Text(device.name).tag(device)
                }
            }

            Picker(StudioStrings.previewOrientationLabel, selection: $configuration.orientation) {
                ForEach(StudioPreviewOrientation.allCases) { orientation in
                    Text(orientation.label).tag(orientation)
                }
            }
            .pickerStyle(.segmented)

            Picker(StudioStrings.previewPresentationLabel, selection: $configuration.presentationMode) {
                ForEach(StudioPreviewPresentationMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }

            Picker(StudioStrings.previewChromeLabel, selection: $configuration.navigationChrome) {
                ForEach(StudioPreviewNavigationChrome.allCases) { chrome in
                    Text(chrome.label).tag(chrome)
                }
            }

            Picker(StudioStrings.previewNavigationDepthLabel, selection: $configuration.navigationDepth) {
                ForEach(StudioPreviewNavigationDepth.allCases) { depth in
                    Text(depth.label).tag(depth)
                }
            }

            Picker(StudioStrings.previewLayeringLabel, selection: $configuration.modalLayering) {
                ForEach(StudioPreviewModalLayering.allCases) { layering in
                    Text(layering.label).tag(layering)
                }
            }

            Picker(StudioStrings.previewStackContext, selection: $configuration.stackContext) {
                ForEach(StudioPreviewStackContext.allCases) { context in
                    Text(StudioStrings.previewStackContextLabel(context)).tag(context)
                }
            }

            Picker(StudioStrings.previewCoverage, selection: $configuration.coverageLevel) {
                ForEach(StudioPreviewCoverageLevel.allCases) { level in
                    Text(level.label).tag(level)
                }
            }

            Toggle(StudioStrings.previewShowSafeAreas, isOn: $configuration.showSafeAreas)
            Toggle(StudioStrings.previewShowDeviceFrame, isOn: $configuration.showDeviceFrame)
        }
    }
}

struct StudioPreviewSurface<Content: View>: View {
    let appearance: StudioNativeAppearance
    let configuration: StudioPreviewConfiguration
    let content: () -> Content

    init(
        appearance: StudioNativeAppearance,
        configuration: StudioPreviewConfiguration,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.appearance = appearance
        self.configuration = configuration
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StudioPreviewHeader(configuration: configuration)

            GeometryReader { proxy in
                let canvasSize = configuration.device.canvasSize(for: configuration.orientation)
                let frameSize = fittedFrameSize(baseSize: canvasSize, in: proxy.size)
                let contentInset = configuration.showDeviceFrame ? configuration.device.bezelPadding * 2 : 0
                let previewSize = CGSize(
                    width: frameSize.width - contentInset,
                    height: frameSize.height - contentInset
                )
                let displayedCanvasSize = fittedCanvasSize(baseSize: canvasSize, in: previewSize)

                ZStack {
                    if configuration.showDeviceFrame {
                        RoundedRectangle(cornerRadius: configuration.device.cornerRadius, style: .continuous)
                            .fill(Color.black.opacity(appearance == .light ? 0.12 : 0.32))
                            .frame(width: frameSize.width, height: frameSize.height)
                    }

                    RoundedRectangle(cornerRadius: max(configuration.device.cornerRadius - 10, 24), style: .continuous)
                        .fill(appearance == .light ? Color.white : Color(hex: "#11182B"))
                        .frame(width: frameSize.width - contentInset, height: frameSize.height - contentInset)
                        .overlay {
                            scaledPreviewSurface(canvasSize: canvasSize)
                        }
                        .overlay {
                            if configuration.showSafeAreas {
                                safeAreaOverlay(in: displayedCanvasSize)
                                    .frame(width: displayedCanvasSize.width, height: displayedCanvasSize.height)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: max(configuration.device.cornerRadius - 10, 24), style: .continuous))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minHeight: 320, idealHeight: 420, maxHeight: 520)
        }
    }

    @ViewBuilder
    private func previewSurface(canvasSize: CGSize) -> some View {
        ZStack {
            previewBackdrop

            if configuration.presentationMode == .sheet {
                Color.black.opacity(appearance == .light ? 0.08 : 0.22)

                ForEach(Array(backgroundModalOffsets.enumerated()), id: \.offset) { _, offset in
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(appearance == .light ? Color.white.opacity(0.72) : Color(hex: "#1D2943").opacity(0.92))
                        .frame(width: sheetSize.width, height: sheetSize.height)
                        .offset(x: offset.width, y: offset.height)
                        .shadow(color: .black.opacity(appearance == .light ? 0.06 : 0.18), radius: 12, y: 6)
                }

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(appearance == .light ? Color.white : Color(hex: "#19233A"))
                    .frame(width: sheetSize.width, height: sheetSize.height)
                    .overlay {
                        content()
                            .padding(.top, chromeGeometry.sheetChromeTopInset + 42)
                            .padding(.horizontal, chromeGeometry.sheetChromeHorizontalInset)
                            .padding(.bottom, 14)
                    }
                    .overlay(alignment: .top) {
                        VStack(spacing: 10) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(width: 42, height: 5)

                            HStack(alignment: .center, spacing: 8) {
                                if let flowBadgeText {
                                    previewBadge(text: flowBadgeText)
                                }
                                if configuration.resolvedModalDepth > 1 {
                                    previewBadge(text: StudioStrings.previewLayerBadge(configuration.resolvedModalDepth))
                                }
                                Spacer(minLength: 0)
                                if showsDismissControl {
                                    Circle()
                                        .fill(Color.secondary.opacity(0.16))
                                        .frame(width: 24, height: 24)
                                        .overlay {
                                            Image(systemName: "xmark")
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(.secondary)
                                        }
                                }
                            }
                        }
                        .padding(.top, chromeGeometry.sheetChromeTopInset)
                        .padding(.horizontal, chromeGeometry.sheetChromeHorizontalInset)
                    }
                    .shadow(color: .black.opacity(appearance == .light ? 0.12 : 0.28), radius: 18, y: 10)
            } else {
                content()
                    .padding(.top, chromeGeometry.topContentInset)
                    .padding(.bottom, chromeGeometry.bottomContentInset)
                    .padding(.horizontal, chromeGeometry.horizontalContentInset)
            }
        }
        .overlay(alignment: .top) {
            if showsNavigationBar {
                previewNavigationBar
            } else if showsFullScreenDismissControl {
                previewFullScreenDismissControl
            }
        }
        .overlay(alignment: .bottom) {
            if showsTabBar {
                previewTabBar
            }
        }
    }

    private func scaledPreviewSurface(canvasSize: CGSize) -> some View {
        GeometryReader { proxy in
            let displayedCanvasSize = fittedCanvasSize(baseSize: canvasSize, in: proxy.size)

            previewSurface(canvasSize: canvasSize)
                .frame(width: canvasSize.width, height: canvasSize.height)
                .scaleEffect(displayedCanvasSize.width / max(canvasSize.width, 1))
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private var previewBackdrop: some View {
        LinearGradient(
            colors: appearance == .light
                ? [Color(hex: "#F4F7FB"), Color.white]
                : [Color(hex: "#0E1526"), Color(hex: "#17233B")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var previewNavigationBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(appearance == .light ? Color.white.opacity(0.92) : Color.black.opacity(0.22))
                .frame(height: chromeGeometry.navigationBarHeight)
                .overlay(alignment: .bottom) {
                    HStack(spacing: 10) {
                        if configuration.navigationDepth != .root {
                            Image(systemName: "chevron.left")
                                .font(.caption.weight(.semibold))
                        }
                        HStack(spacing: 6) {
                            ForEach(configuration.resolvedBreadcrumbTrail, id: \.self) { label in
                                Text(label)
                                    .font(.caption2.weight(label == configuration.resolvedBreadcrumbTrail.last ? .semibold : .regular))
                                    .foregroundStyle(label == configuration.resolvedBreadcrumbTrail.last ? .primary : .secondary)
                                if label != configuration.resolvedBreadcrumbTrail.last {
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .lineLimit(1)
                        Spacer(minLength: 0)
                        HStack(spacing: 6) {
                            if let flowBadgeText {
                                previewBadge(text: flowBadgeText)
                            }
                            if configuration.resolvedModalDepth > 1 {
                                previewBadge(text: StudioStrings.previewLayerBadge(configuration.resolvedModalDepth))
                            }
                            Circle()
                                .fill(Color.secondary.opacity(0.14))
                                .frame(width: 20, height: 20)
                        }
                    }
                    .frame(height: chromeGeometry.navigationContentHeight)
                    .padding(.horizontal, chromeGeometry.horizontalContentInset)
                }
            Divider()
        }
    }

    private var previewFullScreenDismissControl: some View {
        HStack {
            Spacer(minLength: 0)
            Image(systemName: "xmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Color.secondary.opacity(0.14), in: Circle())
        }
        .padding(.top, chromeGeometry.fullScreenDismissTopInset)
        .padding(.horizontal, chromeGeometry.fullScreenDismissHorizontalInset)
    }

    private var previewTabBar: some View {
        VStack(spacing: 0) {
            Divider()
            Rectangle()
                .fill(appearance == .light ? Color.white.opacity(0.94) : Color.black.opacity(0.24))
                .frame(height: chromeGeometry.tabBarHeight)
                .overlay(alignment: .top) {
                    HStack {
                        ForEach(0..<4, id: \.self) { _ in
                            Spacer(minLength: 0)
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(Color.secondary.opacity(0.18))
                                    .frame(width: 16, height: 16)
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.secondary.opacity(0.14))
                                    .frame(width: 28, height: 8)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(height: chromeGeometry.tabContentHeight)
                    .padding(.horizontal, chromeGeometry.horizontalContentInset)
                }
        }
    }

    @ViewBuilder
    private func safeAreaOverlay(in previewSize: CGSize) -> some View {
        let safeArea = configuration.device.safeAreaInsets(for: configuration.orientation)

        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.blue.opacity(0.10))
                .frame(height: scaled(safeArea.top, from: canvasSize.height, to: previewSize.height))
            Spacer(minLength: 0)
            Rectangle()
                .fill(Color.orange.opacity(0.10))
                .frame(height: scaled(safeArea.bottom, from: canvasSize.height, to: previewSize.height))
        }
        .overlay(alignment: .leading) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.green.opacity(0.06))
                    .frame(width: scaled(safeArea.horizontal, from: canvasSize.width, to: previewSize.width))
                Spacer(minLength: 0)
                Rectangle()
                    .fill(Color.green.opacity(0.06))
                    .frame(width: scaled(safeArea.horizontal, from: canvasSize.width, to: previewSize.width))
            }
        }
    }

    private var showsNavigationBar: Bool {
        configuration.navigationChrome == .navigationBar || configuration.navigationChrome == .both
    }

    private var showsTabBar: Bool {
        configuration.navigationChrome == .tabBar || configuration.navigationChrome == .both
    }

    private func fittedFrameSize(baseSize: CGSize, in available: CGSize) -> CGSize {
        let widthRatio = max((available.width - 20) / max(baseSize.width, 1), 0.1)
        let heightRatio = max((available.height - 20) / max(baseSize.height, 1), 0.1)
        let scale = min(widthRatio, heightRatio)
        return CGSize(width: baseSize.width * scale, height: baseSize.height * scale)
    }

    private func fittedCanvasSize(baseSize: CGSize, in available: CGSize) -> CGSize {
        let widthRatio = available.width / max(baseSize.width, 1)
        let heightRatio = available.height / max(baseSize.height, 1)
        let scale = min(widthRatio, heightRatio)
        return CGSize(width: baseSize.width * scale, height: baseSize.height * scale)
    }

    private var canvasSize: CGSize {
        configuration.device.canvasSize(for: configuration.orientation)
    }

    private var chromeGeometry: StudioPreviewChromeGeometry {
        configuration.chromeGeometry
    }

    private func scaled(_ value: CGFloat, from reference: CGFloat, to previewLength: CGFloat) -> CGFloat {
        guard reference > 0 else { return 0 }
        return value / reference * previewLength
    }

    private var showsDismissControl: Bool {
        configuration.presentationMode == .sheet || configuration.presentationMode == .fullScreenCover
    }

    private var showsFullScreenDismissControl: Bool {
        configuration.presentationMode == .fullScreenCover && !showsNavigationBar
    }

    private var sheetSize: CGSize {
        CGSize(
            width: max(canvasSize.width * 0.82, min(canvasSize.width - 28, canvasSize.width * 0.92)),
            height: max(canvasSize.height * 0.72, min(canvasSize.height - 36, canvasSize.height * 0.84))
        )
    }

    private var backgroundModalOffsets: [CGSize] {
        guard configuration.resolvedModalDepth > 1 else { return [] }
        return Array(1..<configuration.resolvedModalDepth).map { layerIndex in
            CGSize(width: 0, height: CGFloat((configuration.resolvedModalDepth - layerIndex) * 8))
        }
    }

    private var flowBadgeText: String? {
        guard let currentStep = configuration.resolvedCurrentStep else { return nil }
        return StudioStrings.previewStepBadge(
            currentStep: currentStep,
            totalSteps: configuration.resolvedTotalSteps
        )
    }

    private func previewBadge(text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(.secondary)
    }
}

private struct StudioPreviewHeader: View {
    let configuration: StudioPreviewConfiguration

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(configuration.device.name)
                    .font(.headline)
                Text(configuration.device.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text(configuration.coverageLevel.label)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(configuration.coverageLevel.color.opacity(0.12), in: Capsule())
                    .foregroundStyle(configuration.coverageLevel.color)
                Text(configuration.orientation.label)
                    .font(.caption.weight(.semibold))
                Text(sizeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(sizeClassLabel)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var sizeLabel: String {
        let size = configuration.device.canvasSize(for: configuration.orientation)
        return "\(Int(size.width)) × \(Int(size.height))"
    }

    private var sizeClassLabel: String {
        StudioStrings.previewSizeClassesValue(
            horizontal: configuration.sizeClasses.horizontal,
            vertical: configuration.sizeClasses.vertical
        )
    }
}

struct StudioPreviewContractPanel: View {
    let configuration: StudioPreviewConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(configuration.coverageLevel.label)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(configuration.coverageLevel.color.opacity(0.14), in: Capsule())
                    .foregroundStyle(configuration.coverageLevel.color)
                Spacer(minLength: 8)
                Text(
                    StudioStrings.previewSizeClassesValue(
                        horizontal: configuration.sizeClasses.horizontal,
                        vertical: configuration.sizeClasses.vertical
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            StudioKeyValueRow(label: StudioStrings.previewContract, value: configuration.contractSummary)
            StudioKeyValueRow(label: StudioStrings.previewBehaviorModel, value: configuration.behaviorSummary)
            StudioKeyValueRow(label: StudioStrings.previewFlowPath, value: configuration.breadcrumbSummary)
            StudioKeyValueRow(label: StudioStrings.previewFlowProgress, value: configuration.flowProgressSummary)
            StudioKeyValueRow(label: StudioStrings.previewModalContext, value: configuration.modalContextSummary)
            StudioKeyValueRow(
                label: StudioStrings.previewSafeArea,
                value: StudioStrings.previewSafeAreaInsets(
                    top: Int(configuration.safeAreaInsets.top),
                    bottom: Int(configuration.safeAreaInsets.bottom),
                    horizontal: Int(configuration.safeAreaInsets.horizontal)
                )
            )
            StudioKeyValueRow(
                label: StudioStrings.previewAppliedChrome,
                value: StudioStrings.previewAppliedChromeOffsets(
                    top: Int(configuration.chromeGeometry.topContentInset),
                    bottom: Int(configuration.chromeGeometry.bottomContentInset),
                    horizontal: Int(configuration.chromeGeometry.horizontalContentInset)
                )
            )
            StudioKeyValueRow(label: StudioStrings.previewStackContext, value: configuration.stackContext.summary)
            StudioKeyValueRow(label: StudioStrings.previewContractNoteLabel, value: configuration.contractNoteSummary)
            StudioKeyValueRow(label: StudioStrings.previewCoverageNote, value: configuration.coverageLevel.summary)
        }
        .padding(14)
        .background(.quaternary.opacity(0.32), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct StudioPreviewHero: View {
    let url: URL?
    let appearance: StudioNativeAppearance
    let configuration: StudioPreviewConfiguration
    let layoutMode: StudioPreviewLayoutMode
    let emptyTitle: String
    let emptySymbolName: String

    var body: some View {
        StudioPreviewSurface(appearance: appearance, configuration: configuration) {
            previewContent
        }
        .frame(
            minHeight: layoutMode == .focus ? 460 : 320,
            idealHeight: layoutMode == .focus ? 560 : 420,
            maxHeight: layoutMode == .focus ? 680 : 520
        )
    }

    private var previewContent: some View {
        Group {
            if let url, url.isFileURL, let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(14)
            } else if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(14)
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
    }

    private var fallback: some View {
        VStack(spacing: 10) {
            Image(systemName: emptySymbolName)
                .font(.system(size: 28, weight: .semibold))
            Text(emptyTitle)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.secondary)
    }
}

struct StudioPreviewLayoutPicker: View {
    @Binding var layoutMode: StudioPreviewLayoutMode

    var body: some View {
        Picker(StudioStrings.previewScale, selection: $layoutMode) {
            ForEach(StudioPreviewLayoutMode.allCases) { mode in
                Text(mode.label).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
}
