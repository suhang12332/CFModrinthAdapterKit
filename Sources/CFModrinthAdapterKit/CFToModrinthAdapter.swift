import Foundation

/// 提供纯数据层的 CurseForge -> Modrinth 转换工具
/// 仅依赖本包内的模型类型，不依赖应用层工具或常量。
public enum CFToModrinthAdapter {
    /// 将 CurseForge 项目详情转换为 Modrinth 项目详情格式
    /// - Parameters:
    ///   - cf: CurseForge 项目详情
    ///   - descriptionHTML: 从 description 接口获取的 HTML 描述内容（可选，如果提供则优先作为 body）
    /// - Returns: Modrinth 格式的项目详情
    public static func convertProjectDetail(
        _ cf: CurseForgeModDetail,
        descriptionHTML: String = ""
    ) -> ModrinthProjectDetail? {
        // 日期解析器（ISO8601，带毫秒）
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // 解析日期
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

        // 提取游戏版本（从 latestFilesIndexes）
        var gameVersions: [String] = []
        if let indexes = cf.latestFilesIndexes {
            let allVersions = Set(indexes.map { $0.gameVersion })
            gameVersions = Array(allVersions)
        }

        // 提取加载器（从 latestFilesIndexes）
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

        // 基于 classId 推断项目类型字符串（与主工程 ResourceType.rawValue 对应）
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

        // 如果 loaders 为空，根据项目类型填充默认值
        if loaders.isEmpty {
            if projectType == "resourcepack" {
                loaders = ["minecraft"]
            } else if projectType == "datapack" {
                loaders = ["datapack"]
            }
        }

        // 提取版本 ID 列表
        var versions: [String] = []
        if let files = cf.latestFiles {
            versions = files.map { String($0.id) }
        }

        // 提取分类
        let categories = cf.categories.map { $0.slug }

        // 提取图标 URL
        let iconUrl = cf.logo?.url ?? cf.logo?.thumbnailUrl

        // CurseForge 通常没有明确的许可证信息，这里给出占位
        let license = License(id: "unknown", name: "Unknown", url: nil)

        // 使用 "cf-" 前缀标识 CurseForge 项目，避免与 Modrinth 项目混淆
        // body 优先使用 HTML 描述，其次使用 body 字段，最后使用 summary
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

    /// 将 CurseForge 文件详情转换为 Modrinth 版本格式
    /// - Parameters:
    ///   - cfFile: CurseForge 文件详情
    ///   - projectId: 项目 ID（可带或不带 "cf-" 前缀）
    /// - Returns: Modrinth 格式的版本详情
    public static func convertFile(
        _ cfFile: CurseForgeModFileDetail,
        projectId: String
    ) -> ModrinthProjectDetailVersion? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // 解析发布日期
        let publishedDate: Date
        if !cfFile.fileDate.isEmpty,
           let parsed = dateFormatter.date(from: cfFile.fileDate) {
            publishedDate = parsed
        } else {
            publishedDate = Date()
        }

        // 版本类型统一视为 release
        let versionType = "release"

        // 文件级别不推断加载器，保持空数组
        let loaders: [String] = []

        // 转换依赖
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
                    projectId: String(dep.modId),
                    versionId: nil,
                    dependencyType: dependencyType
                )
            }
        }

        // 下载 URL：优先使用 API 提供的 downloadUrl
        let downloadUrl = cfFile.downloadUrl ?? ""

        // 提取哈希值：优先使用 hashes 数组，如果没有则使用 hash 字段
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

        // 确保 projectId 使用 "cf-" 前缀
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

    /// 将 CurseForge 搜索结果转换为 Modrinth 搜索结果
    /// - Parameter cfResult: CurseForge 搜索结果
    /// - Returns: Modrinth 格式的搜索结果
    public static func convertSearchResult(
        _ cfResult: CurseForgeSearchResult
    ) -> ModrinthResult {
        let hits: [ModrinthProject] = cfResult.data.compactMap { cfMod in
            // 确定项目类型
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

            // 提取版本 ID 列表
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
                displayCategories: [],
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

    /// 从 HTML 内容中提取纯文本作为简短描述
    /// - Parameter html: HTML 字符串
    /// - Returns: 提取的纯文本（限制长度）
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
}

