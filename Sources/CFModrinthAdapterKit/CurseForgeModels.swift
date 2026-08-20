import Foundation

/// CurseForge search result containing a list of mods and pagination info.
public struct CurseForgeSearchResult: Codable {
    public let data: [CurseForgeMod]
    public let pagination: CurseForgePagination?

    public init(data: [CurseForgeMod], pagination: CurseForgePagination?) {
        self.data = data
        self.pagination = pagination
    }
}

/// CurseForge pagination metadata.
public struct CurseForgePagination: Codable {
    public let index: Int
    public let pageSize: Int
    public let resultCount: Int
    public let totalCount: Int

    public init(index: Int, pageSize: Int, resultCount: Int, totalCount: Int) {
        self.index = index
        self.pageSize = pageSize
        self.resultCount = resultCount
        self.totalCount = totalCount
    }
}

/// CurseForge mod summary returned from search endpoints.
public struct CurseForgeMod: Codable {
    public let id: Int
    public let name: String
    public let summary: String
    public let slug: String?
    public let authors: [CurseForgeAuthor]?
    public let logo: CurseForgeLogo?
    public let downloadCount: Int?
    public let gamePopularityRank: Int?
    public let links: CurseForgeLinks?
    public let dateCreated: String?
    public let dateModified: String?
    public let dateReleased: String?
    public let gameId: Int?
    public let classId: Int?
    public let categories: [CurseForgeCategory]?
    public let latestFiles: [CurseForgeModFileDetail]?
    public let latestFilesIndexes: [CurseForgeFileIndex]?

    enum CodingKeys: String, CodingKey {
        case id, name, summary, slug, authors, logo
        case downloadCount
        case gamePopularityRank
        case links
        case dateCreated
        case dateModified
        case dateReleased
        case gameId
        case classId
        case categories
        case latestFiles
        case latestFilesIndexes
    }
}

/// CurseForge mod logo / thumbnail.
public struct CurseForgeLogo: Codable {
    public let id: Int?
    public let modId: Int?
    public let title: String?
    public let description: String?
    public let thumbnailUrl: String?
    public let url: String?
}

/// CurseForge external links associated with a mod.
public struct CurseForgeLinks: Codable {
    public let websiteUrl: String?
    public let wikiUrl: String?
    public let issuesUrl: String?
    public let sourceUrl: String?
}

/// CurseForge mod detail returned from the mod info endpoint.
public struct CurseForgeModDetail: Codable {
    public let id: Int
    public let name: String
    public let summary: String
    public let classId: Int
    public let categories: [CurseForgeCategory]
    public let slug: String?
    public let authors: [CurseForgeAuthor]?
    public let logo: CurseForgeLogo?
    public let downloadCount: Int?
    public let gamePopularityRank: Int?
    public let links: CurseForgeLinks?
    public let dateCreated: String?
    public let dateModified: String?
    public let dateReleased: String?
    public let gameId: Int?
    public let latestFiles: [CurseForgeModFileDetail]?
    public let latestFilesIndexes: [CurseForgeFileIndex]?
    public let body: String?

    /// The content type derived from `classId`.
    public var contentType: CurseForgeClassId? {
        CurseForgeClassId(rawValue: classId)
    }
}

/// CurseForge file version index entry.
public struct CurseForgeFileIndex: Codable {
    public let gameVersion: String
    public let fileId: Int
    public let filename: String
    public let releaseType: Int
    public let gameVersionTypeId: Int?
    public let modLoader: Int?
}

/// CurseForge content type identifiers.
public enum CurseForgeClassId: Int, CaseIterable {
    case mods = 6
    case resourcePacks = 12
    case shaders = 6552
    case datapacks = 6945
    case modpacks = 4471
}

/// CurseForge mod loader type identifiers.
public enum CurseForgeModLoaderType: Int, CaseIterable {
    case forge = 1
    case fabric = 4
    case quilt = 5
    case neoforge = 6

    /// The Modrinth-compatible loader name.
    public var name: String {
        switch self {
        case .forge: return "forge"
        case .fabric: return "fabric"
        case .quilt: return "quilt"
        case .neoforge: return "neoforge"
        }
    }

    /// Returns the loader type for a given name string.
    public static func from(_ loaderName: String) -> Self? {
        switch loaderName.lowercased() {
        case "forge": return .forge
        case "fabric": return .fabric
        case "quilt": return .quilt
        case "neoforge": return .neoforge
        default: return nil
        }
    }
}

/// CurseForge category model.
public struct CurseForgeCategory: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let slug: String
    public let url: String?
    public let avatarUrl: String?
    public let parentCategoryId: Int?
    public let rootCategoryId: Int?
    public let gameId: Int?
    public let gameName: String?
    public let classId: Int?
    public let dateModified: String?
}

/// CurseForge categories list response.
public struct CurseForgeCategoriesResponse: Codable {
    public let data: [CurseForgeCategory]
}

/// CurseForge game version model.
public struct CurseForgeGameVersion: Codable, Identifiable, Hashable {
    public let id: Int
    public let gameVersionId: Int?
    public let versionString: String
    public let jarDownloadUrl: String?
    public let jsonDownloadUrl: String?
    public let approved: Bool
    public let dateModified: String?
    public let gameVersionTypeId: Int?
    public let gameVersionStatus: Int?
    public let gameVersionTypeStatus: Int?

    public var identifier: String { versionString }

    public var version_type: String {
        // CurseForge does not have explicit version types; infer from version string
        if versionString.contains("snapshot") || versionString.contains("pre") || versionString.contains("rc") {
            return "snapshot"
        }
        return "release"
    }
}

/// CurseForge game versions list response.
public struct CurseForgeGameVersionsResponse: Codable {
    public let data: [CurseForgeGameVersion]
}

/// CurseForge mod detail single-item response wrapper.
public struct CurseForgeModDetailResponse: Codable {
    public let data: CurseForgeModDetail
}

/// CurseForge mod description response wrapper.
public struct CurseForgeModDescriptionResponse: Codable {
    public let data: String
}

/// CurseForge files list response wrapper.
public struct CurseForgeFilesResult: Codable {
    public let data: [CurseForgeModFileDetail]
}

/// CurseForge file detail model.
public struct CurseForgeModFileDetail: Codable {
    public let id: Int
    public let displayName: String
    public let fileName: String
    public let downloadUrl: String?
    public let fileDate: String
    public let releaseType: Int
    public let gameVersions: [String]
    public let dependencies: [CurseForgeDependency]?
    public let changelog: String?
    public let fileLength: Int?
    public let hash: CurseForgeHash?
    public let hashes: [CurseForgeHash]?
    public let modules: [CurseForgeModule]?
    public let projectId: Int?
    public let projectName: String?
    public let authors: [CurseForgeAuthor]?

    public init(
        id: Int,
        displayName: String,
        fileName: String,
        downloadUrl: String?,
        fileDate: String,
        releaseType: Int,
        gameVersions: [String],
        dependencies: [CurseForgeDependency]?,
        changelog: String?,
        fileLength: Int?,
        hash: CurseForgeHash?,
        hashes: [CurseForgeHash]?,
        modules: [CurseForgeModule]?,
        projectId: Int?,
        projectName: String?,
        authors: [CurseForgeAuthor]?
    ) {
        self.id = id
        self.displayName = displayName
        self.fileName = fileName
        self.downloadUrl = downloadUrl
        self.fileDate = fileDate
        self.releaseType = releaseType
        self.gameVersions = gameVersions
        self.dependencies = dependencies
        self.changelog = changelog
        self.fileLength = fileLength
        self.hash = hash
        self.hashes = hashes
        self.modules = modules
        self.projectId = projectId
        self.projectName = projectName
        self.authors = authors
    }
}

/// CurseForge dependency relationship between files.
public struct CurseForgeDependency: Codable {
    public let modId: Int
    public let relationType: Int
}

/// CurseForge file hash value and algorithm identifier.
public struct CurseForgeHash: Codable {
    public let value: String
    public let algo: Int
}

/// CurseForge module metadata for a file.
public struct CurseForgeModule: Codable {
    public let name: String
    public let fingerprint: Int
}

/// CurseForge author information.
public struct CurseForgeAuthor: Codable {
    public let name: String
    public let url: String?
}

// MARK: - CurseForge Manifest Models

/// CurseForge modpack manifest.json format.
public struct CurseForgeManifest: Codable {
    public let minecraft: CurseForgeMinecraft
    public let manifestType: String
    public let manifestVersion: Int
    public let name: String
    public let version: String?
    public let author: String?
    public let files: [CurseForgeManifestFile]
    public let overrides: String?

    enum CodingKeys: String, CodingKey {
        case minecraft
        case manifestType
        case manifestVersion
        case name
        case version
        case author
        case files
        case overrides
    }
}

/// CurseForge manifest Minecraft configuration.
public struct CurseForgeMinecraft: Codable {
    public let version: String
    public let modLoaders: [CurseForgeModLoader]
}

/// CurseForge manifest mod loader entry.
public struct CurseForgeModLoader: Codable {
    public let id: String
    public let primary: Bool
}

/// CurseForge manifest file reference.
public struct CurseForgeManifestFile: Codable {
    public let projectID: Int
    public let fileID: Int
    public let required: Bool

    enum CodingKeys: String, CodingKey {
        case projectID
        case fileID
        case required
    }
}

/// CurseForge modpack index information (converted format).
public struct CurseForgeIndexInfo {
    public let gameVersion: String
    public let loaderType: String
    public let loaderVersion: String
    public let modPackName: String
    public let modPackVersion: String
    public let author: String?
    public let files: [CurseForgeManifestFile]
    public let overridesPath: String?
}

// MARK: - Fingerprint Models

/// CurseForge fingerprint match request.
public struct CurseForgeFingerprintMatchesRequest: Codable {
    public let fingerprints: [UInt32]

    public init(fingerprints: [UInt32]) {
        self.fingerprints = fingerprints
    }
}

/// CurseForge fingerprint match response.
public struct CurseForgeFingerprintMatchesResponse: Codable {
    public let data: CurseForgeFingerprintMatchesData

    public init(data: CurseForgeFingerprintMatchesData) {
        self.data = data
    }
}

/// CurseForge fingerprint match result data.
public struct CurseForgeFingerprintMatchesData: Codable {
    public let exactMatches: [CurseForgeFingerprintMatch]?
    public let partialMatches: [CurseForgeFingerprintMatch]?

    public init(
        exactMatches: [CurseForgeFingerprintMatch]?,
        partialMatches: [CurseForgeFingerprintMatch]?
    ) {
        self.exactMatches = exactMatches
        self.partialMatches = partialMatches
    }
}

/// CurseForge fingerprint match entry.
public struct CurseForgeFingerprintMatch: Codable {
    public let file: CurseForgeFingerprintFile?

    public init(file: CurseForgeFingerprintFile?) {
        self.file = file
    }
}

/// CurseForge fingerprint file information.
public struct CurseForgeFingerprintFile: Codable {
    public let modId: Int
    public let id: Int

    public init(modId: Int, id: Int) {
        self.modId = modId
        self.id = id
    }
}
