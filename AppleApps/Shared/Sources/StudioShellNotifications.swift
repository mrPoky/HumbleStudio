import Foundation

extension Notification.Name {
    static let studioOpenQuickOpen = Notification.Name("StudioShell.openQuickOpen")
    static let studioOpenImport = Notification.Name("StudioShell.openImport")
    static let studioReopenRecentImport = Notification.Name("StudioShell.reopenRecentImport")
    static let studioOpenRemoteURL = Notification.Name("StudioShell.openRemoteURL")
    static let studioReopenRecentRemoteURL = Notification.Name("StudioShell.reopenRecentRemoteURL")
    static let studioNavigateBack = Notification.Name("StudioShell.navigateBack")
    static let studioNavigateForward = Notification.Name("StudioShell.navigateForward")
    static let studioLoadDemo = Notification.Name("StudioShell.loadDemo")
    static let studioLoadHome = Notification.Name("StudioShell.loadHome")
    static let studioReload = Notification.Name("StudioShell.reload")
}
