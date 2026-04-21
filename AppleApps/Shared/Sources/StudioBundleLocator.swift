import Foundation

enum StudioBundleError: LocalizedError {
    case missingResourceRoot
    case missingIndex

    var errorDescription: String? {
        switch self {
        case .missingResourceRoot:
            return "The bundled HumbleStudio web assets could not be found."
        case .missingIndex:
            return "The bundled HumbleStudio index.html file is missing."
        }
    }
}

enum StudioBundleLocator {
    static let bundleFolderName = "WebStudio"

    static func resourceRoot(in bundle: Bundle = .main) throws -> URL {
        guard let rootURL = bundle.resourceURL?.appendingPathComponent(bundleFolderName, isDirectory: true) else {
            throw StudioBundleError.missingResourceRoot
        }

        guard FileManager.default.fileExists(atPath: rootURL.path) else {
            throw StudioBundleError.missingResourceRoot
        }

        return rootURL
    }

    static func bundledIndexURL(in bundle: Bundle = .main) throws -> URL {
        guard let indexURL = bundle.url(forResource: "index", withExtension: "html", subdirectory: bundleFolderName) else {
            throw StudioBundleError.missingIndex
        }

        return indexURL
    }
}
