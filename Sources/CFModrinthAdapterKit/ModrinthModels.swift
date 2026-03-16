import Foundation

// Modrinth 项目模型
public struct ModrinthProject: Codable {
    public let projectId: String
    public let projectType: String
    public let slug: String
    public let author: String
    public let title: String
    public let description: String
    public let categories: [String]
    public let displayCategories: [String]
    public let versions: [String]
    public let downloads: Int
    public let follows: Int
    public let iconUrl: String?
    public let license: String
    public let clientSide: String
    public let serverSide: String
    public let fileName: String?

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case projectType = "project_type"
        case slug, author, title, description, categories
        case displayCategories = "display_categories"
        case versions, downloads, follows
        case iconUrl = "icon_url"
        case license
        case clientSide = "client_side"
        case serverSide = "server_side"
        case fileName
    }

    public init(
        projectId: String,
        projectType: String,
        slug: String,
        author: String,
        title: String,
        description: String,
        categories: [String],
        displayCategories: [String],
        versions: [String],
        downloads: Int,
        follows: Int,
        iconUrl: String?,
        license: String,
        clientSide: String,
        serverSide: String,
    ) {
        self.projectId = projectId
        self.projectType = projectType
        self.slug = slug
        self.author = author
        self.title = title
        self.description = description
        self.categories = categories
        self.displayCategories = displayCategories
        self.versions = versions
        self.downloads = downloads
        self.follows = follows
        self.iconUrl = iconUrl
        self.license = license
        self.clientSide = clientSide
        self.serverSide = serverSide
    }
}

public struct ModrinthProjectDetail: Codable, Hashable, Equatable {
    public let slug: String
    public let title: String
    public let description: String
    public let categories: [String]
    public let clientSide: String
    public let serverSide: String
    public let body: String
    public let additionalCategories: [String]?
    public let issuesUrl: String?
    public let sourceUrl: String?
    public let wikiUrl: String?
    public let discordUrl: String?
    public let projectType: String
    public let downloads: Int
    public let iconUrl: String?
    public let id: String
    public let team: String
    public let published: Date
    public let updated: Date
    public let followers: Int
    public let license: License?
    public let versions: [String]
    public var gameVersions: [String]
    public let loaders: [String]
    public var type: String?
    public var fileName: String?

    enum CodingKeys: String, CodingKey {
        case slug
        case title
        case description
        case categories
        case clientSide = "client_side"
        case serverSide = "server_side"
        case body
        case additionalCategories = "additional_categories"
        case issuesUrl = "issues_url"
        case sourceUrl = "source_url"
        case wikiUrl = "wiki_url"
        case discordUrl = "discord_url"
        case projectType = "project_type"
        case downloads
        case iconUrl = "icon_url"
        case id
        case team
        case published
        case updated
        case followers
        case license
        case versions
        case gameVersions = "game_versions"
        case loaders
        case type
        case fileName
    }

    public init(
        slug: String,
        title: String,
        description: String,
        categories: [String],
        clientSide: String,
        serverSide: String,
        body: String,
        additionalCategories: [String]?,
        issuesUrl: String?,
        sourceUrl: String?,
        wikiUrl: String?,
        discordUrl: String?,
        projectType: String,
        downloads: Int,
        iconUrl: String?,
        id: String,
        team: String,
        published: Date,
        updated: Date,
        followers: Int,
        license: License?,
        versions: [String],
        gameVersions: [String],
        loaders: [String],
        type: String?,
        fileName: String?
    ) {
        self.slug = slug
        self.title = title
        self.description = description
        self.categories = categories
        self.clientSide = clientSide
        self.serverSide = serverSide
        self.body = body
        self.additionalCategories = additionalCategories
        self.issuesUrl = issuesUrl
        self.sourceUrl = sourceUrl
        self.wikiUrl = wikiUrl
        self.discordUrl = discordUrl
        self.projectType = projectType
        self.downloads = downloads
        self.iconUrl = iconUrl
        self.id = id
        self.team = team
        self.published = published
        self.updated = updated
        self.followers = followers
        self.license = license
        self.versions = versions
        self.gameVersions = gameVersions
        self.loaders = loaders
        self.type = type
        self.fileName = fileName
    }
}

// Modrinth 搜索结果模型
public struct ModrinthResult: Codable {
    public let hits: [ModrinthProject]
    public let offset: Int
    public let limit: Int
    public let totalHits: Int

    public init(hits: [ModrinthProject], offset: Int, limit: Int, totalHits: Int) {
        self.hits = hits
        self.offset = offset
        self.limit = limit
        self.totalHits = totalHits
    }

    enum CodingKeys: String, CodingKey {
        case hits, offset, limit
        case totalHits = "total_hits"
    }
}

// 游戏版本
public struct GameVersion: Codable, Identifiable, Hashable {
    public let version: String
    public let version_type: String
    public let date: String
    public let major: Bool

    public var id: String { version }
}

// 加载器
public struct Loader: Codable, Identifiable {
    public let name: String
    public let icon: String
    public let supported_project_types: [String]

    public var id: String { name }

    public init(name: String, icon: String, supported_project_types: [String]) {
        self.name = name
        self.icon = icon
        self.supported_project_types = supported_project_types
    }
}

// 分类
public struct Category: Codable, Identifiable, Hashable {
    public let name: String
    public let project_type: String
    public let header: String

    public var id: String { name }
}

// 许可证
public struct License: Codable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let url: String?

    public init(id: String, name: String, url: String?) {
        self.id = id
        self.name = name
        self.url = url
    }
}

/// Modrinth version model
public struct ModrinthProjectDetailVersion: Codable, Identifiable, Equatable, Hashable {
    public let gameVersions: [String]
    public let loaders: [String]
    public let id: String
    public let projectId: String
    public let authorId: String
    public let featured: Bool
    public let name: String
    public let versionNumber: String
    public let changelog: String?
    public let changelogUrl: String?
    public let datePublished: Date
    public let downloads: Int
    public let versionType: String
    public let status: String
    public let requestedStatus: String?
    public let files: [ModrinthVersionFile]
    public let dependencies: [ModrinthVersionDependency]

    enum CodingKeys: String, CodingKey {
        case gameVersions = "game_versions"
        case loaders
        case id
        case projectId = "project_id"
        case authorId = "author_id"
        case featured
        case name
        case versionNumber = "version_number"
        case changelog
        case changelogUrl = "changelog_url"
        case datePublished = "date_published"
        case downloads
        case versionType = "version_type"
        case status
        case requestedStatus = "requested_status"
        case files
        case dependencies
    }

    public init(
        gameVersions: [String],
        loaders: [String],
        id: String,
        projectId: String,
        authorId: String,
        featured: Bool,
        name: String,
        versionNumber: String,
        changelog: String?,
        changelogUrl: String?,
        datePublished: Date,
        downloads: Int,
        versionType: String,
        status: String,
        requestedStatus: String?,
        files: [ModrinthVersionFile],
        dependencies: [ModrinthVersionDependency]
    ) {
        self.gameVersions = gameVersions
        self.loaders = loaders
        self.id = id
        self.projectId = projectId
        self.authorId = authorId
        self.featured = featured
        self.name = name
        self.versionNumber = versionNumber
        self.changelog = changelog
        self.changelogUrl = changelogUrl
        self.datePublished = datePublished
        self.downloads = downloads
        self.versionType = versionType
        self.status = status
        self.requestedStatus = requestedStatus
        self.files = files
        self.dependencies = dependencies
    }
}

/// Modrinth version file model
public struct ModrinthVersionFile: Codable, Equatable, Hashable {
    public let hashes: ModrinthVersionFileHashes
    public let url: String
    public let filename: String
    public let primary: Bool
    public let size: Int
    public let fileType: String?

    enum CodingKeys: String, CodingKey {
        case hashes
        case url
        case filename
        case primary
        case size
        case fileType = "file_type"
    }

    public init(
        hashes: ModrinthVersionFileHashes,
        url: String,
        filename: String,
        primary: Bool,
        size: Int,
        fileType: String?
    ) {
        self.hashes = hashes
        self.url = url
        self.filename = filename
        self.primary = primary
        self.size = size
        self.fileType = fileType
    }
}

/// Modrinth version file hashes model
public struct ModrinthVersionFileHashes: Codable, Equatable, Hashable {
    public let sha512: String
    public let sha1: String

    public init(sha512: String, sha1: String) {
        self.sha512 = sha512
        self.sha1 = sha1
    }
}

/// Modrinth version dependency model
public struct ModrinthVersionDependency: Codable, Equatable, Hashable {
    public let projectId: String?
    public let versionId: String?
    public let dependencyType: String

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case versionId = "version_id"
        case dependencyType = "dependency_type"
    }

    public init(projectId: String?, versionId: String?, dependencyType: String) {
        self.projectId = projectId
        self.versionId = versionId
        self.dependencyType = dependencyType
    }
}

public struct ModrinthProjectDependency: Codable, Hashable, Equatable {
    public let projects: [ModrinthProjectDetailVersion]

    public init(projects: [ModrinthProjectDetailVersion]) {
        self.projects = projects
    }
}

// MARK: - Modrinth Project Detail V3

public struct ModrinthProjectDetailV3: Codable, Hashable, Equatable {
    public let id: String
    public let slug: String
    public let projectTypes: [String]
    public let games: [String]
    public let gameVersions: [String]
    public let teamId: String
    public let organization: String?
    public let name: String
    public let summary: String
    public let description: String
    public let published: Date
    public let updated: Date
    public let approved: Date?
    public let queued: Date?
    public let status: String
    public let requestedStatus: String
    public let moderatorMessage: String?
    public let license: License
    public let downloads: Int
    public let followers: Int
    public let categories: [String]
    public let additionalCategories: [String]
    public let loaders: [String]
    public let versions: [String]
    public let iconUrl: String?
    public let linkUrls: ModrinthProjectLinkUrls?
    public let gallery: [ModrinthProjectGalleryItem]
    public let color: Int?
    public let threadId: String?
    public let monetizationStatus: String?
    public let sideTypesMigrationReviewStatus: String?
    public let minecraftServer: ModrinthMinecraftServerInfo?
    public let minecraftJavaServer: ModrinthMinecraftJavaServerInfo?
    public let minecraftBedrockServer: ModrinthMinecraftBedrockServerInfo?

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case projectTypes = "project_types"
        case games
        case gameVersions = "game_versions"
        case teamId = "team_id"
        case organization
        case name
        case summary
        case description
        case published
        case updated
        case approved
        case queued
        case status
        case requestedStatus = "requested_status"
        case moderatorMessage = "moderator_message"
        case license
        case downloads
        case followers
        case categories
        case additionalCategories = "additional_categories"
        case loaders
        case versions
        case iconUrl = "icon_url"
        case linkUrls = "link_urls"
        case gallery
        case color
        case threadId = "thread_id"
        case monetizationStatus = "monetization_status"
        case sideTypesMigrationReviewStatus = "side_types_migration_review_status"
        case minecraftServer = "minecraft_server"
        case minecraftJavaServer = "minecraft_java_server"
        case minecraftBedrockServer = "minecraft_bedrock_server"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        slug = try container.decode(String.self, forKey: .slug)
        projectTypes = try container.decode([String].self, forKey: .projectTypes)
        games = try container.decode([String].self, forKey: .games)
        gameVersions = try container.decodeIfPresent([String].self, forKey: .gameVersions) ?? []
        teamId = try container.decode(String.self, forKey: .teamId)
        organization = try container.decodeIfPresent(String.self, forKey: .organization)
        name = try container.decode(String.self, forKey: .name)
        summary = try container.decode(String.self, forKey: .summary)
        description = try container.decode(String.self, forKey: .description)
        published = try container.decode(Date.self, forKey: .published)
        updated = try container.decode(Date.self, forKey: .updated)
        approved = try container.decodeIfPresent(Date.self, forKey: .approved)
        queued = try container.decodeIfPresent(Date.self, forKey: .queued)
        status = try container.decode(String.self, forKey: .status)
        requestedStatus = try container.decode(String.self, forKey: .requestedStatus)
        moderatorMessage = try container.decodeIfPresent(String.self, forKey: .moderatorMessage)
        license = try container.decode(License.self, forKey: .license)
        downloads = try container.decode(Int.self, forKey: .downloads)
        followers = try container.decode(Int.self, forKey: .followers)
        categories = try container.decode([String].self, forKey: .categories)
        additionalCategories = try container.decode([String].self, forKey: .additionalCategories)
        loaders = try container.decode([String].self, forKey: .loaders)
        versions = try container.decode([String].self, forKey: .versions)
        iconUrl = try container.decodeIfPresent(String.self, forKey: .iconUrl)
        linkUrls = try container.decodeIfPresent(ModrinthProjectLinkUrls.self, forKey: .linkUrls)
        gallery = try container.decode([ModrinthProjectGalleryItem].self, forKey: .gallery)
        color = try container.decodeIfPresent(Int.self, forKey: .color)
        threadId = try container.decodeIfPresent(String.self, forKey: .threadId)
        monetizationStatus = try container.decodeIfPresent(String.self, forKey: .monetizationStatus)
        sideTypesMigrationReviewStatus = try container.decodeIfPresent(String.self, forKey: .sideTypesMigrationReviewStatus)
        minecraftServer = try container.decodeIfPresent(ModrinthMinecraftServerInfo.self, forKey: .minecraftServer)
        minecraftJavaServer = try container.decodeIfPresent(ModrinthMinecraftJavaServerInfo.self, forKey: .minecraftJavaServer)
        minecraftBedrockServer = try container.decodeIfPresent(ModrinthMinecraftBedrockServerInfo.self, forKey: .minecraftBedrockServer)
    }
}

public struct ModrinthProjectLinkUrls: Codable, Hashable, Equatable {
    public let store: ModrinthProjectLinkUrl?
    public let wiki: ModrinthProjectLinkUrl?
    public let discord: ModrinthProjectLinkUrl?
    public let site: ModrinthProjectLinkUrl?
}

public struct ModrinthProjectLinkUrl: Codable, Hashable, Equatable {
    public let platform: String
    public let donation: Bool
    public let url: String
}

public struct ModrinthProjectGalleryItem: Codable, Hashable, Equatable {
    public let url: String
    public let rawUrl: String
    public let featured: Bool
    public let name: String
    public let description: String?
    public let created: Date
    public let ordering: Int

    enum CodingKeys: String, CodingKey {
        case url
        case rawUrl = "raw_url"
        case featured
        case name
        case description
        case created
        case ordering
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(String.self, forKey: .url)
        rawUrl = try container.decode(String.self, forKey: .rawUrl)
        featured = try container.decode(Bool.self, forKey: .featured)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        created = try container.decode(Date.self, forKey: .created)
        ordering = try container.decode(Int.self, forKey: .ordering)
    }
}

public struct ModrinthMinecraftServerInfo: Codable, Hashable, Equatable {
    public let maxPlayers: Int?
    public let country: String?
    public let region: String?
    public let languages: [String]
    public let activeVersion: String?

    enum CodingKeys: String, CodingKey {
        case maxPlayers = "max_players"
        case country
        case region
        case languages
        case activeVersion = "active_version"
    }
}

public struct ModrinthMinecraftJavaServerInfo: Codable, Hashable, Equatable {
    public let address: String
    public let content: ModrinthMinecraftJavaServerContent?
    public let ping: ModrinthMinecraftJavaServerPing?
    public let verifiedPlays2w: Int?
    public let verifiedPlays4w: Int?

    enum CodingKeys: String, CodingKey {
        case address
        case content
        case ping
        case verifiedPlays2w = "verified_plays_2w"
        case verifiedPlays4w = "verified_plays_4w"
    }
}

public struct ModrinthMinecraftJavaServerContent: Codable, Hashable, Equatable {
    public let kind: String

    public let versionId: String?
    public let projectId: String?
    public let projectName: String?
    public let projectIcon: String?
    public let supportedGameVersions: [String]?
    public let recommendedGameVersion: String?

    enum CodingKeys: String, CodingKey {
        case kind
        case versionId = "version_id"
        case projectId = "project_id"
        case projectName = "project_name"
        case projectIcon = "project_icon"
        case supportedGameVersions = "supported_game_versions"
        case recommendedGameVersion = "recommended_game_version"
    }
}

public struct ModrinthMinecraftJavaServerPing: Codable, Hashable, Equatable {
    public let when: Date
    public let address: String
    public let data: ModrinthMinecraftJavaServerPingData
}

public struct ModrinthMinecraftJavaServerPingData: Codable, Hashable, Equatable {
    public let latency: ModrinthLatency
    public let versionName: String
    public let versionProtocol: Int
    public let description: String
    public let playersOnline: Int
    public let playersMax: Int

    enum CodingKeys: String, CodingKey {
        case latency
        case versionName = "version_name"
        case versionProtocol = "version_protocol"
        case description
        case playersOnline = "players_online"
        case playersMax = "players_max"
    }
}

public struct ModrinthLatency: Codable, Hashable, Equatable {
    public let secs: Int
    public let nanos: Int
}

public struct ModrinthMinecraftBedrockServerInfo: Codable, Hashable, Equatable {
    public let address: String
}
