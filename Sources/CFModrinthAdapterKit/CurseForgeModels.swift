import Foundation

public struct CurseForgeSearchResult: Codable {
    public let data: [CurseForgeMod]
    public let pagination: CurseForgePagination?

    public init(data: [CurseForgeMod], pagination: CurseForgePagination?) {
        self.data = data
        self.pagination = pagination
    }
}

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

public struct CurseForgeLogo: Codable {
    public let id: Int?
    public let modId: Int?
    public let title: String?
    public let description: String?
    public let thumbnailUrl: String?
    public let url: String?
}

public struct CurseForgeLinks: Codable {
    public let websiteUrl: String?
    public let wikiUrl: String?
    public let issuesUrl: String?
    public let sourceUrl: String?
}

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

    /// 对应的内容类型枚举（纯模型：不依赖主工程常量）
    public var contentType: CurseForgeClassId? {
        CurseForgeClassId(rawValue: classId)
    }
}

public struct CurseForgeFileIndex: Codable {
    public let gameVersion: String
    public let fileId: Int
    public let filename: String
    public let releaseType: Int
    public let gameVersionTypeId: Int?
    public let modLoader: Int?
}

/// CurseForge 内容类型枚举
public enum CurseForgeClassId: Int, CaseIterable {
    case mods = 6           // 模组
    case resourcePacks = 12 // 资源包
    case shaders = 6552     // 光影
    case datapacks = 6945   // 数据包
    case modpacks = 4471    // 整合包（Modpacks）
}

/// CurseForge ModLoaderType 枚举
public enum CurseForgeModLoaderType: Int, CaseIterable {
    case forge = 1
    case fabric = 4
    case quilt = 5
    case neoforge = 6

    /// 根据字符串获取对应的枚举值
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

/// CurseForge 分类列表响应
public struct CurseForgeCategoriesResponse: Codable {
    public let data: [CurseForgeCategory]
}

/// CurseForge 游戏版本
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
        // CurseForge 没有明确的版本类型，根据版本号推断
        if versionString.contains("snapshot") || versionString.contains("pre") || versionString.contains("rc") {
            return "snapshot"
        }
        return "release"
    }
}

/// CurseForge 游戏版本列表响应
public struct CurseForgeGameVersionsResponse: Codable {
    public let data: [CurseForgeGameVersion]
}

public struct CurseForgeModDetailResponse: Codable {
    public let data: CurseForgeModDetail
}

public struct CurseForgeModDescriptionResponse: Codable {
    public let data: String
}

public struct CurseForgeFilesResult: Codable {
    public let data: [CurseForgeModFileDetail]
}

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

    /// 从 hashes 数组中提取 algo 为 1 的 hash（SHA1）
    public var sha1Hash: CurseForgeHash? {
        if let hashes {
            return hashes.first { $0.algo == 1 }
        }
        return hash
    }
}

public struct CurseForgeDependency: Codable {
    public let modId: Int
    public let relationType: Int
}

public struct CurseForgeHash: Codable {
    public let value: String
    public let algo: Int
}

public struct CurseForgeModule: Codable {
    public let name: String
    public let fingerprint: Int
}

public struct CurseForgeAuthor: Codable {
    public let name: String
    public let url: String?
}

// MARK: - CurseForge Manifest Models

/// CurseForge 整合包的 manifest.json 格式
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

/// CurseForge manifest 中的 Minecraft 配置
public struct CurseForgeMinecraft: Codable {
    public let version: String
    public let modLoaders: [CurseForgeModLoader]
}

/// CurseForge manifest 中的模组加载器配置
public struct CurseForgeModLoader: Codable {
    public let id: String
    public let primary: Bool
}

/// CurseForge manifest 中的文件信息
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

/// CurseForge 整合包索引信息（转换后的格式）
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
