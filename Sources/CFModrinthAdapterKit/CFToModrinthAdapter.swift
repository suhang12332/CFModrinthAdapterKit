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
        let publishedDate = parseDate(cf.dateCreated)
        let updatedDate = parseDate(cf.dateModified)

        // Extract game versions from latestFilesIndexes
        var gameVersions: [String] = []
        if let indexes = cf.latestFilesIndexes {
            gameVersions = Array(Set(indexes.map { $0.gameVersion }))
        }

        // Extract loaders from latestFilesIndexes
        var loaders = loaderNames(from: cf.latestFilesIndexes)

        // Infer the project type string from classId
        let projectType = projectType(for: cf.classId)

        // Populate default loaders when none are present
        if loaders.isEmpty {
            if projectType == "resourcepack" {
                loaders = ["minecraft"]
            } else if projectType == "datapack" {
                loaders = ["datapack"]
            }
        }

        // Extract version ID list
        let versions = versionIDs(from: cf.latestFiles)

        // Extract categories
        let categories = cf.categories.map { $0.slug }

        // Extract icon URL
        let iconUrl = iconURL(for: cf.logo)

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
        let publishedDate = parseDate(cfFile.fileDate)

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
        var sha512 = ""
        var sha1 = ""
        if let hashesArray = cfFile.hashes, !hashesArray.isEmpty {
            sha1 = hashesArray.first { $0.algo == 1 }?.value ?? ""
            sha512 = hashesArray.first { $0.algo == 2 }?.value ?? ""
        } else if let hash = cfFile.hash {
            switch hash.algo {
            case 1:
                sha1 = hash.value
            case 2:
                sha512 = hash.value
            default:
                break
            }
        }
        let hashes = ModrinthVersionFileHashes(sha512: sha512, sha1: sha1)

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
            let projectType = projectType(for: cfMod.classId ?? CurseForgeClassId.mods.rawValue)

            // Extract version ID list
            let versions = versionIDs(from: cfMod.latestFiles)

            // Extract categories
            let categories = cfMod.categories?.map { $0.slug } ?? []

            return ModrinthProject(
                projectId: "cf-\(cfMod.id)",
                projectType: projectType,
                slug: cfMod.slug ?? "curseforge-\(cfMod.id)",
                author: cfMod.authors?.first?.name ?? "Unknown",
                title: cfMod.name,
                description: cfMod.summary,
                categories: categories,
                displayCategories: categories,
                versions: versions,
                downloads: cfMod.downloadCount ?? 0,
                follows: 0,
                iconUrl: iconURL(for: cfMod.logo),
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

    // MARK: - Private helpers

    /// Parses an ISO8601 date string, falling back to the current date.
    private static func parseDate(_ string: String?) -> Date {
        guard let string else { return Date() }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string) ?? Date()
    }

    /// Maps a CurseForge classId to a Modrinth project type string.
    private static func projectType(for classId: Int) -> String {
        switch classId {
        case CurseForgeClassId.mods.rawValue:
            return "mod"
        case CurseForgeClassId.resourcePacks.rawValue:
            return "resourcepack"
        case CurseForgeClassId.shaders.rawValue:
            return "shader"
        case CurseForgeClassId.datapacks.rawValue:
            return "datapack"
        case CurseForgeClassId.modpacks.rawValue:
            return "modpack"
        default:
            return "mod"
        }
    }

    /// Extracts Modrinth version IDs from a CurseForge file list.
    private static func versionIDs(from files: [CurseForgeModFileDetail]?) -> [String] {
        files?.map { String($0.id) } ?? []
    }

    /// Maps CurseForge loader raw values to Modrinth loader names.
    private static func loaderNames(from indexes: [CurseForgeFileIndex]?) -> [String] {
        guard let indexes else { return [] }
        let loaderTypes = Set(indexes.compactMap { $0.modLoader })
        return loaderTypes.compactMap { CurseForgeModLoaderType(rawValue: $0)?.name }
    }

    /// Extracts the primary icon URL from a CurseForge logo, falling back to the thumbnail.
    private static func iconURL(for logo: CurseForgeLogo?) -> String? {
        logo?.url ?? logo?.thumbnailUrl
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
