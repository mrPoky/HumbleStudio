import SwiftUI

enum StudioPreviewOrientation: String, CaseIterable, Identifiable {
    case portrait
    case landscape

    var id: String { rawValue }
}

enum StudioPreviewSizeClass: String {
    case compact
    case regular

    var label: String { rawValue.capitalized }
}

enum StudioPreviewPresentationMode: String, CaseIterable, Identifiable {
    case push = "Push"
    case sheet = "Sheet"
    case fullScreenCover = "Full Screen"

    var id: String { rawValue }
}

enum StudioPreviewNavigationChrome: String, CaseIterable, Identifiable {
    case none = "None"
    case navigationBar = "Navigation"
    case tabBar = "Tab Bar"
    case both = "Both"

    var id: String { rawValue }
}

enum StudioPreviewNavigationDepth: String, CaseIterable, Identifiable {
    case root = "Root"
    case detail = "Detail"
    case deep = "Deep Link"

    var id: String { rawValue }
}

enum StudioPreviewModalLayering: String, CaseIterable, Identifiable {
    case inline = "Inline"
    case elevated = "Elevated"
    case blocking = "Blocking"

    var id: String { rawValue }
}

enum StudioPreviewStackContext: String, CaseIterable, Identifiable {
    case single = "Single Screen"
    case stacked = "Stacked Flow"
    case branched = "Branched Flow"

    var id: String { rawValue }

    var summary: String {
        switch self {
        case .single:
            return "Inspecting one isolated surface without surrounding flow baggage."
        case .stacked:
            return "Inspecting a screen inside a straightforward parent-child navigation stack."
        case .branched:
            return "Inspecting a screen inside a larger flow with alternate routes, overlays, or exits."
        }
    }

    var breadcrumbLabels: [String] {
        switch self {
        case .single:
            return ["Current"]
        case .stacked:
            return ["Home", "Detail", "Current"]
        case .branched:
            return ["Home", "Flow", "Review", "Current"]
        }
    }
}

enum StudioPreviewCoverageLevel: String, CaseIterable, Identifiable {
    case exact = "Exact"
    case contractDriven = "Contract-driven"
    case fallbackNeeded = "Fallback needed"

    var id: String { rawValue }

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
        switch self {
        case .exact:
            return "Reference-backed preview with strong exported visual truth."
        case .contractDriven:
            return "Behavior is modeled natively from the contract, but still approximated."
        case .fallbackNeeded:
            return "Native preview is still incomplete here and may require fallback inspection."
        }
    }
}

enum StudioPreviewLayoutMode: String, CaseIterable, Identifiable {
    case regular = "Fit"
    case focus = "Focus"

    var id: String { rawValue }
}

struct StudioPreviewDevice: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let portraitSize: CGSize
    let landscapeSize: CGSize
    let cornerRadius: CGFloat
    let bezelPadding: CGFloat
    let safeAreaTop: CGFloat
    let safeAreaBottom: CGFloat
    let safeAreaHorizontal: CGFloat
    let notes: String

    func canvasSize(for orientation: StudioPreviewOrientation) -> CGSize {
        orientation == .portrait ? portraitSize : landscapeSize
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

enum StudioPreviewCatalog {
    static let devices: [StudioPreviewDevice] = [
        StudioPreviewDevice(
            id: "iphone-compact",
            name: "iPhone Compact",
            portraitSize: CGSize(width: 393, height: 852),
            landscapeSize: CGSize(width: 852, height: 393),
            cornerRadius: 44,
            bezelPadding: 18,
            safeAreaTop: 59,
            safeAreaBottom: 34,
            safeAreaHorizontal: 0,
            notes: "Phone-first compact viewport for everyday navigation and sheet checks."
        ),
        StudioPreviewDevice(
            id: "iphone-plus",
            name: "iPhone Plus",
            portraitSize: CGSize(width: 430, height: 932),
            landscapeSize: CGSize(width: 932, height: 430),
            cornerRadius: 48,
            bezelPadding: 20,
            safeAreaTop: 59,
            safeAreaBottom: 34,
            safeAreaHorizontal: 0,
            notes: "Larger phone viewport for dense content and action spacing checks."
        ),
        StudioPreviewDevice(
            id: "ipad-portrait",
            name: "iPad Portrait",
            portraitSize: CGSize(width: 834, height: 1194),
            landscapeSize: CGSize(width: 1194, height: 834),
            cornerRadius: 36,
            bezelPadding: 18,
            safeAreaTop: 24,
            safeAreaBottom: 20,
            safeAreaHorizontal: 0,
            notes: "Tablet viewport for split layouts, popovers, and longer reading flows."
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

    var sizeClasses: (horizontal: StudioPreviewSizeClass, vertical: StudioPreviewSizeClass) {
        device.sizeClasses(for: orientation)
    }

    var contractSummary: String {
        "\(device.name) · \(orientation.rawValue.capitalized) · \(presentationMode.rawValue) · \(navigationChrome.rawValue) · \(navigationDepth.rawValue) · \(stackContext.rawValue)"
    }

    var behaviorSummary: String {
        "\(presentationMode.rawValue) flow with \(navigationChrome.rawValue.lowercased()) chrome, \(navigationDepth.rawValue.lowercased()) route depth, \(modalLayering.rawValue.lowercased()) layering, and a \(stackContext.rawValue.lowercased()) context."
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
            Picker("Device", selection: $configuration.device) {
                ForEach(StudioPreviewCatalog.devices) { device in
                    Text(device.name).tag(device)
                }
            }

            Picker("Orientation", selection: $configuration.orientation) {
                ForEach(StudioPreviewOrientation.allCases) { orientation in
                    Text(orientation.rawValue.capitalized).tag(orientation)
                }
            }
            .pickerStyle(.segmented)

            Picker("Presentation", selection: $configuration.presentationMode) {
                ForEach(StudioPreviewPresentationMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            Picker("Chrome", selection: $configuration.navigationChrome) {
                ForEach(StudioPreviewNavigationChrome.allCases) { chrome in
                    Text(chrome.rawValue).tag(chrome)
                }
            }

            Picker("Navigation depth", selection: $configuration.navigationDepth) {
                ForEach(StudioPreviewNavigationDepth.allCases) { depth in
                    Text(depth.rawValue).tag(depth)
                }
            }

            Picker("Layering", selection: $configuration.modalLayering) {
                ForEach(StudioPreviewModalLayering.allCases) { layering in
                    Text(layering.rawValue).tag(layering)
                }
            }

            Picker("Stack context", selection: $configuration.stackContext) {
                ForEach(StudioPreviewStackContext.allCases) { context in
                    Text(context.rawValue).tag(context)
                }
            }

            Picker("Coverage", selection: $configuration.coverageLevel) {
                ForEach(StudioPreviewCoverageLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }

            Toggle("Show safe areas", isOn: $configuration.showSafeAreas)
            Toggle("Show device frame", isOn: $configuration.showDeviceFrame)
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
                            previewSurface(canvasSize: canvasSize)
                        }
                        .overlay {
                            if configuration.showSafeAreas {
                                safeAreaOverlay(for: canvasSize)
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

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(appearance == .light ? Color.white : Color(hex: "#19233A"))
                    .frame(
                        width: max(canvasSize.width * 0.82, min(canvasSize.width - 28, canvasSize.width * 0.92)),
                        height: max(canvasSize.height * 0.72, min(canvasSize.height - 36, canvasSize.height * 0.84))
                    )
                    .overlay {
                        content()
                            .padding(14)
                    }
                    .overlay(alignment: .top) {
                        VStack(spacing: 10) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(width: 42, height: 5)

                            if showsDismissControl {
                                HStack {
                                    Spacer(minLength: 0)
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
                        .padding(.top, 10)
                        .padding(.horizontal, 12)
                    }
                    .shadow(color: .black.opacity(appearance == .light ? 0.12 : 0.28), radius: 18, y: 10)
            } else {
                content()
                    .padding(.top, topChromePadding)
                    .padding(.bottom, bottomChromePadding)
                    .padding(.horizontal, 14)
            }
        }
        .overlay(alignment: .top) {
            if showsNavigationBar {
                previewNavigationBar
            }
        }
        .overlay(alignment: .bottom) {
            if showsTabBar {
                previewTabBar
            }
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
                .frame(height: 52)
                .overlay {
                    HStack(spacing: 10) {
                        if configuration.navigationDepth != .root {
                            Image(systemName: "chevron.left")
                                .font(.caption.weight(.semibold))
                        }
                        HStack(spacing: 6) {
                            ForEach(configuration.stackContext.breadcrumbLabels, id: \.self) { label in
                                Text(label)
                                    .font(.caption2.weight(label == "Current" ? .semibold : .regular))
                                    .foregroundStyle(label == "Current" ? .primary : .secondary)
                                if label != configuration.stackContext.breadcrumbLabels.last {
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .lineLimit(1)
                        Spacer(minLength: 0)
                        if showsDismissControl {
                            Circle()
                                .fill(Color.secondary.opacity(0.14))
                                .frame(width: 20, height: 20)
                        } else {
                            Circle()
                                .fill(Color.secondary.opacity(0.14))
                                .frame(width: 20, height: 20)
                        }
                    }
                    .padding(.horizontal, 14)
                }
            Divider()
        }
    }

    private var previewTabBar: some View {
        VStack(spacing: 0) {
            Divider()
            Rectangle()
                .fill(appearance == .light ? Color.white.opacity(0.94) : Color.black.opacity(0.24))
                .frame(height: 58)
                .overlay {
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
                }
        }
    }

    private func safeAreaOverlay(for canvasSize: CGSize) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.blue.opacity(0.10))
                .frame(height: scaled(configuration.device.safeAreaTop, over: canvasSize.height))
            Spacer(minLength: 0)
            Rectangle()
                .fill(Color.orange.opacity(0.10))
                .frame(height: scaled(configuration.device.safeAreaBottom, over: canvasSize.height))
        }
        .overlay(alignment: .leading) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.green.opacity(0.06))
                    .frame(width: scaled(configuration.device.safeAreaHorizontal, over: canvasSize.width))
                Spacer(minLength: 0)
                Rectangle()
                    .fill(Color.green.opacity(0.06))
                    .frame(width: scaled(configuration.device.safeAreaHorizontal, over: canvasSize.width))
            }
        }
    }

    private var showsNavigationBar: Bool {
        configuration.navigationChrome == .navigationBar || configuration.navigationChrome == .both
    }

    private var showsTabBar: Bool {
        configuration.navigationChrome == .tabBar || configuration.navigationChrome == .both
    }

    private var topChromePadding: CGFloat {
        showsNavigationBar || configuration.presentationMode == .fullScreenCover ? 58 : 14
    }

    private var bottomChromePadding: CGFloat {
        showsTabBar ? 70 : 14
    }

    private func fittedFrameSize(baseSize: CGSize, in available: CGSize) -> CGSize {
        let widthRatio = max((available.width - 20) / max(baseSize.width, 1), 0.1)
        let heightRatio = max((available.height - 20) / max(baseSize.height, 1), 0.1)
        let scale = min(widthRatio, heightRatio)
        return CGSize(width: baseSize.width * scale, height: baseSize.height * scale)
    }

    private func scaled(_ value: CGFloat, over total: CGFloat) -> CGFloat {
        let canvasSize = configuration.device.canvasSize(for: configuration.orientation)
        let reference = total == canvasSize.height ? canvasSize.height : canvasSize.width
        guard reference > 0 else { return 0 }
        return value / reference * total
    }

    private var showsDismissControl: Bool {
        configuration.presentationMode == .sheet || configuration.presentationMode == .fullScreenCover
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
                Text(configuration.coverageLevel.rawValue)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(configuration.coverageLevel.color.opacity(0.12), in: Capsule())
                    .foregroundStyle(configuration.coverageLevel.color)
                Text(configuration.orientation.rawValue.capitalized)
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
        let sizeClasses = configuration.sizeClasses
        return "H \(sizeClasses.horizontal.label) · V \(sizeClasses.vertical.label)"
    }
}

struct StudioPreviewContractPanel: View {
    let configuration: StudioPreviewConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(configuration.coverageLevel.rawValue)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(configuration.coverageLevel.color.opacity(0.14), in: Capsule())
                    .foregroundStyle(configuration.coverageLevel.color)
                Spacer(minLength: 8)
                Text("H \(configuration.sizeClasses.horizontal.label) · V \(configuration.sizeClasses.vertical.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            StudioKeyValueRow(label: "Preview contract", value: configuration.contractSummary)
            StudioKeyValueRow(label: "Behavior model", value: configuration.behaviorSummary)
            StudioKeyValueRow(label: "Stack context", value: configuration.stackContext.summary)
            StudioKeyValueRow(label: "Coverage note", value: configuration.coverageLevel.summary)
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
        Picker("Preview scale", selection: $layoutMode) {
            ForEach(StudioPreviewLayoutMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
}
