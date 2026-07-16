import SwiftUI

struct StudioSupportedAppSource: Identifiable, Equatable {
    let id: String
    let name: String
    let repo: String
    let sourceSummary: String
    let remoteURL: String
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
}

struct StudioSupportedRemoteAppsSection: View {
    @Binding var remoteURLDraft: String

    var body: some View {
        Section(StudioStrings.supportedAppsTitle) {
            Text(StudioStrings.supportedAppsPrompt)
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(StudioSupportedAppCatalog.all) { app in
                Button {
                    remoteURLDraft = app.remoteURL
                } label: {
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

                        if remoteURLDraft == app.remoteURL {
                            Label(StudioStrings.current, systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.semibold))
                                .labelStyle(.titleAndIcon)
                        } else {
                            Text(StudioStrings.useURL)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tint)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
