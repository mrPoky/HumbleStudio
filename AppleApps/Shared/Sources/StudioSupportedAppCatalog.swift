import SwiftUI

struct StudioSupportedAppSource: Identifiable, Equatable {
    let id: String
    let name: String
    let repo: String
    let sourceSummary: String
    let remoteURL: String

    var sourceLabel: String {
        "\(name) · \(repo)"
    }
}

enum StudioSupportedAppCatalog {
    static let all: [StudioSupportedAppSource] = [
        StudioSupportedAppSource(
            id: "humble-sudoku",
            name: "HumbleSudoku",
            repo: "mrPoky/HumbleSudoku",
            sourceSummary: ".humble/HumbleSudoku.humblebundle",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/HumbleSudoku/main/.humble/HumbleSudoku.humblebundle"
        ),
        StudioSupportedAppSource(
            id: "my-vltava-run",
            name: "MyVltavaRun",
            repo: "mrPoky/MyVltavaRun",
            sourceSummary: ".humble/design.json",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/MyVltavaRun/main/.humble/design.json"
        ),
        StudioSupportedAppSource(
            id: "humble-control",
            name: "HumbleControl",
            repo: "mrPoky/HumbleControl",
            sourceSummary: ".humble/design.json",
            remoteURL: "https://raw.githubusercontent.com/mrPoky/HumbleControl/main/.humble/design.json"
        ),
    ]

    static var remotePlaceholder: String {
        all.first?.remoteURL ?? "https://raw.githubusercontent.com/user/repo/main/.humble/design.json"
    }

    static func app(forRemoteURL remoteURL: String?) -> StudioSupportedAppSource? {
        guard let remoteURL else { return nil }
        let trimmed = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return all.first(where: { $0.remoteURL == trimmed })
    }
}

struct StudioSupportedRemoteAppsSection: View {
    @Binding var remoteURLDraft: String
    let loadApp: ((StudioSupportedAppSource) -> Void)?

    var body: some View {
        Section(StudioStrings.supportedAppsTitle) {
            Text(StudioStrings.supportedAppsPrompt)
                .font(.footnote)
                .foregroundStyle(.secondary)

            StudioSupportedAppsList(
                selectedRemoteURL: remoteURLDraft,
                useURL: { remoteURLDraft = $0.remoteURL },
                loadApp: loadApp
            )
        }
    }
}

struct StudioSupportedAppsCard: View {
    let selectedRemoteURL: String?
    let loadApp: (StudioSupportedAppSource) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(StudioStrings.supportedAppsTitle)
                .font(.headline)

            Text(StudioStrings.supportedAppsPrompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            StudioSupportedAppsList(
                selectedRemoteURL: selectedRemoteURL,
                useURL: nil,
                loadApp: loadApp
            )
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.quaternary.opacity(0.8), lineWidth: 1)
        )
    }
}

private struct StudioSupportedAppsList: View {
    let selectedRemoteURL: String?
    let useURL: ((StudioSupportedAppSource) -> Void)?
    let loadApp: ((StudioSupportedAppSource) -> Void)?

    var body: some View {
        ForEach(StudioSupportedAppCatalog.all) { app in
            StudioSupportedAppRow(
                app: app,
                isCurrent: selectedRemoteURL == app.remoteURL,
                useURL: useURL,
                loadApp: loadApp
            )
        }
    }
}

private struct StudioSupportedAppRow: View {
    let app: StudioSupportedAppSource
    let isCurrent: Bool
    let useURL: ((StudioSupportedAppSource) -> Void)?
    let loadApp: ((StudioSupportedAppSource) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(app.repo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(app.sourceSummary)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 8) {
                if isCurrent {
                    Label(StudioStrings.current, systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                }

                if let useURL {
                    Button(StudioStrings.useURL) {
                        useURL(app)
                    }
                    .buttonStyle(.borderless)
                }

                if let loadApp {
                    Button(StudioStrings.loadNow) {
                        loadApp(app)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
