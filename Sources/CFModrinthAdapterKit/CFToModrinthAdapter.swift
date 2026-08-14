import Foundation

/// Provides pure data-layer conversion utilities from CurseForge to Modrinth.
/// Depends only on model types within this package; no application-layer constants or utilities.
public enum CFToModrinthAdapter {

    /// Converts a CurseForge mod detail to the Modrinth project detail format.
    /// - Parameters:
    ///   - cf: The CurseForge mod detail to convert.
    ///   - descriptionHTML: An optional HTML description retrieved from the description endpoint.
    ///     When provided, it takes precedence as the project body.
    /// - Returns: A Modrinth project detail, or `nil` if conversion fails.
    public static func convertProjectDetail(
        _ cf: CurseForgeModDetail,
        descriptionHTML: String = ""
    ) -> ModrinthProjectDetail? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let publishedDate: Date
        if let dateCreated = cf.dateCreated,
           let parsed = dateFormatter.date(from: dateCreated) {
            publishedDate = parsed
        } else {
            publishedDate = Date()
        }

        let updatedDate: Date
        if let dateModified = cf.dateModified,
           let parsed = dateFormatter.date(from: dateModified) {
            updatedDate = parsed
        } else {
            updatedDate = Date()
        }

        // Extract game versions from latestFilesIndexes
        var gameVersions: [String] = []
        if let indexes = cf.latestFilesIndexes {
            let allVersions = Set(indexes.map { $0.gameVersion })
            gameVersions = Array(allVersions)
        }

        // Extract loaders from latestFilesIndexes
        var loaders: [String] = []
        if let indexes = cf.latestFilesIndexes {
            let loaderTypes = Set(indexes.compactMap { $0.modLoader })
            for loaderType in loaderTypes {
                if let loader = CurseForgeModLoaderType(rawValue: loaderType) {
                    switch loader {
                    case .forge:
                        loaders.append("forge")
                    case .fabric:
                        loaders.append("fabric")
                    case .quilt:
                        loaders.append("quilt")
                    case .neoforge:
                        loaders.append("neoforge")
                    }
                }
            }
        }

        // Infer the project type string from classId
        let projectType: String
        switch cf.classId {
        case CurseForgeClassId.mods.rawValue:
            projectType = "mod"
        case CurseForgeClassId.resourcePacks.rawValue:
            projectType = "resourcepack"
        case CurseForgeClassId.shaders.rawValue:
            projectType = "shader"
        case CurseForgeClassId.datapacks.rawValue:
            projectType = "datapack"
        case CurseForgeClassId.modpacks.rawValue:
            projectType = "modpack"
        default:
            projectType = "mod"
        }

        // Populate default loaders when none are present
        if loaders.isEmpty {
            if projectType == "resourcepack" {
                loaders = ["minecraft"]
            } else if projectType == "datapack" {
                loaders = ["datapack"]
            }
        }

        // Extract version ID list
        var versions: [String] = []
        if let files = cf.latestFiles {
            versions = files.map { String($0.id) }
        }

        // Extract categories
        let categories = cf.categories.map { $0.slug }

        // Extract icon URL
        let iconUrl = cf.logo?.url ?? cf.logo?.thumbnailUrl

        // CurseForge rarely provides explicit license information; use a placeholder
        let license = License(id: "unknown", name: "Unknown", url: nil)

        // Use a "cf-" prefix to distinguish CurseForge projects from Modrinth projects.
        // The body prefers the HTML description, falls back to the body field, then to summary.
        let bodyContent = descriptionHTML.isEmpty ? (cf.body ?? cf.summary) : descriptionHTML
        let descriptionText = descriptionHTML.isEmpty
            ? cf.summary
            : extractPlainText(from: descriptionHTML)

        return ModrinthProjectDetail(
            slug: cf.slug ?? "curseforge-\(cf.id)",
            title: cf.name,
            description: descriptionText,
            categories: categories,
            clientSide: "optional",
            serverSide: "optional",
            body: bodyContent,
            additionalCategories: nil,
            issuesUrl: cf.links?.issuesUrl,
            sourceUrl: cf.links?.sourceUrl,
            wikiUrl: cf.links?.wikiUrl ?? cf.links?.websiteUrl,
            discordUrl: nil,
            projectType: projectType,
            downloads: cf.downloadCount ?? 0,
            iconUrl: iconUrl,
            id: "cf-\(cf.id)",
            team: "",
            published: publishedDate,
            updated: updatedDate,
            followers: 0,
            license: license,
            versions: versions,
            gameVersions: gameVersions,
            loaders: loaders,
            type: projectType,
            fileName: nil
        )
    }

    /// Converts a CurseForge file detail to the Modrinth version format.
    /// - Parameters:
    ///   - cfFile: The CurseForge file detail to convert.
    ///   - projectId: The project ID, with or without the "cf-" prefix.
    /// - Returns: A Modrinth version detail, or `nil` if conversion fails.
    public static func convertFile(
        _ cfFile: CurseForgeModFileDetail,
        projectId: String
    ) -> ModrinthProjectDetailVersion? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let publishedDate: Date
        if !cfFile.fileDate.isEmpty,
           let parsed = dateFormatter.date(from: cfFile.fileDate) {
            publishedDate = parsed
        } else {
            publishedDate = Date()
        }

        // Treat all versions as release type
        let versionType = "release"

        // File-level conversion does not infer loaders; leave empty
        let loaders: [String] = []

        // Convert dependencies
        var dependencies: [ModrinthVersionDependency] = []
        if let cfDeps = cfFile.dependencies {
            dependencies = cfDeps.compactMap { dep in
                // relationType: 1 = EmbeddedLibrary, 2 = OptionalDependency,
                //               3 = RequiredDependency, 4 = Tool, 5 = Incompatible
                let dependencyType: String
                switch dep.relationType {
                case 3:
                    dependencyType = "required"
                case 2:
                    dependencyType = "optional"
                case 5:
                    dependencyType = "incompatible"
                default:
                    dependencyType = "optional"
                }

                return ModrinthVersionDependency(
                    projectId: "cf-\(dep.modId)",
                    versionId: nil,
                    dependencyType: dependencyType
                )
            }
        }

        // Download URL: prefer the one provided by the API
        let downloadUrl = cfFile.downloadUrl ?? fallbackDownloadUrl(fileId: cfFile.id, fileName: cfFile.fileName).absoluteString

        // Extract hashes: prefer the hashes array, fall back to the single hash field
        let hashes: ModrinthVersionFileHashes
        if let hashesArray = cfFile.hashes, !hashesArray.isEmpty {
            let sha1Hash = hashesArray.first { $0.algo == 1 }
            let sha512Hash = hashesArray.first { $0.algo == 2 }
            hashes = ModrinthVersionFileHashes(
                sha512: sha512Hash?.value ?? "",
                sha1: sha1Hash?.value ?? ""
            )
        } else if let hash = cfFile.hash {
            switch hash.algo {
            case 1:
                hashes = ModrinthVersionFileHashes(sha512: "", sha1: hash.value)
            case 2:
                hashes = ModrinthVersionFileHashes(sha512: hash.value, sha1: "")
            default:
                hashes = ModrinthVersionFileHashes(sha512: "", sha1: "")
            }
        } else {
            hashes = ModrinthVersionFileHashes(sha512: "", sha1: "")
        }

        let files: [ModrinthVersionFile] = [
            ModrinthVersionFile(
                hashes: hashes,
                url: downloadUrl,
                filename: cfFile.fileName,
                primary: true,
                size: cfFile.fileLength ?? 0,
                fileType: nil
            )
        ]

        // Ensure the project ID uses the "cf-" prefix
        let cleanId = projectId.replacingOccurrences(of: "cf-", with: "")
        let normalizedProjectId = "cf-\(cleanId)"

        return ModrinthProjectDetailVersion(
            gameVersions: cfFile.gameVersions,
            loaders: loaders,
            id: "cf-\(cfFile.id)",
            projectId: normalizedProjectId,
            authorId: cfFile.authors?.first?.name ?? "unknown",
            featured: false,
            name: cfFile.displayName,
            versionNumber: cfFile.displayName,
            changelog: cfFile.changelog,
            changelogUrl: nil,
            datePublished: publishedDate,
            downloads: 0,
            versionType: versionType,
            status: "listed",
            requestedStatus: nil,
            files: files,
            dependencies: dependencies
        )
    }

    /// Converts a CurseForge search result to the Modrinth search result format.
    /// - Parameter cfResult: The CurseForge search result to convert.
    /// - Returns: A Modrinth-formatted search result.
    public static func convertSearchResult(
        _ cfResult: CurseForgeSearchResult
    ) -> ModrinthResult {
        let hits: [ModrinthProject] = cfResult.data.compactMap { cfMod in
            // Determine the project type
            let projectType: String
            if let classId = cfMod.classId,
               let type = CurseForgeClassId(rawValue: classId) {
                switch type {
                case .mods:
                    projectType = "mod"
                case .resourcePacks:
                    projectType = "resourcepack"
                case .shaders:
                    projectType = "shader"
                case .datapacks:
                    projectType = "datapack"
                case .modpacks:
                    projectType = "modpack"
                }
            } else {
                projectType = "mod"
            }

            // Extract version ID list
            var versions: [String] = []
            if let files = cfMod.latestFiles {
                versions = files.map { String($0.id) }
            }

            return ModrinthProject(
                projectId: "cf-\(cfMod.id)",
                projectType: projectType,
                slug: cfMod.slug ?? "curseforge-\(cfMod.id)",
                author: cfMod.authors?.first?.name ?? "Unknown",
                title: cfMod.name,
                description: cfMod.summary,
                categories: cfMod.categories?.map { $0.slug } ?? [],
                displayCategories: cfMod.categories?.map { $0.slug } ?? [],
                versions: versions,
                downloads: cfMod.downloadCount ?? 0,
                follows: 0,
                iconUrl: cfMod.logo?.url ?? cfMod.logo?.thumbnailUrl,
                license: "",
                clientSide: "optional",
                serverSide: "optional",
                fileName: nil
            )
        }

        let pagination = cfResult.pagination
        let offset = pagination?.index ?? 0
        let limit = pagination?.pageSize ?? hits.count
        let totalHits = pagination?.totalCount ?? hits.count

        return ModrinthResult(
            hits: hits,
            offset: offset,
            limit: limit,
            totalHits: totalHits
        )
    }

    /// Extracts plain text from an HTML string for use as a short description.
    /// - Parameter html: The HTML string to process.
    /// - Returns: Plain text truncated to 200 characters.
    private static func extractPlainText(from html: String) -> String {
        let text = html
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if text.count > 200 {
            return String(text.prefix(200)) + "..."
        }
        return text
    }

    /// Builds a fallback download URL for CurseForge files when the API does not provide one.
    /// - Parameters:
    ///   - fileId: The CurseForge file ID.
    ///   - fileName: The original file name.
    /// - Returns: A fully constructed download URL.
    static func fallbackDownloadUrl(fileId: Int, fileName: String) -> URL {
        // Format: https://edge.forgecdn.net/files/{first3digits}/{last3digits}/{fileName}
        url("https://edge.forgecdn.net/files")
            .appendingPathComponent("\(fileId / 1000)")
            .appendingPathComponent("\(fileId % 1000)")
            .appendingPathComponent(fileName)
    }

    private static func url(_ string: String) -> URL {
        URL(string: string) ?? URL(string: "https://localhost")!
    }
}
