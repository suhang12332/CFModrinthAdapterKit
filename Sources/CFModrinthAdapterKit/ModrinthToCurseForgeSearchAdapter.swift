import Foundation

/// Converts Modrinth-style search parameters into CurseForge API-compatible parameters.
/// A pure data-layer utility that depends only on models within this package.
public enum ModrinthToCurseForgeSearchAdapter {

    /// CurseForge search parameter structure for building query strings.
    public struct SearchParams {
        public let classId: Int?
        public let categoryIds: [Int]?
        public let gameVersions: [String]?
        public let searchFilter: String?
        public let modLoaderTypes: [Int]?

        public init(
            classId: Int?,
            categoryIds: [Int]?,
            gameVersions: [String]?,
            searchFilter: String?,
            modLoaderTypes: [Int]?
        ) {
            self.classId = classId
            self.categoryIds = categoryIds
            self.gameVersions = gameVersions
            self.searchFilter = searchFilter
            self.modLoaderTypes = modLoaderTypes
        }
    }

    /// Converts Modrinth search parameters to CurseForge search parameters.
    /// - Parameters:
    ///   - projectType: The project type (e.g. `"mod"`, `"modpack"`, `"resourcepack"`, `"shader"`, `"datapack"`).
    ///   - versions: A list of game versions.
    ///   - categories: A list of behavior/function category names.
    ///   - resolutions: A list of resource pack resolutions (only applies to `resourcepack` type).
    ///   - loaders: A list of mod loader names (e.g. `"forge"`, `"fabric"`, `"quilt"`, `"neoforge"`).
    ///   - query: The search query string.
    /// - Returns: A ``SearchParams`` structure ready for CurseForge URL construction.
    /// - Note: CurseForge API limits are automatically enforced:
    ///   - `gameVersions`: maximum 4 items
    ///   - `modLoaderTypes`: maximum 5 items
    ///   - `categoryIds`: maximum 10 items
    public static func convertToSearchParams(
        projectType: String,
        versions: [String],
        categories: [String],
        resolutions: [String],
        loaders: [String],
        query: String
    ) -> SearchParams {
        // 1. Map project type to classId
        let classId = classIdForProjectType(projectType)

        // 2. Game versions (max 4)
        let gameVersions: [String]?
        if !versions.isEmpty {
            gameVersions = Array(versions.prefix(4))
        } else {
            gameVersions = nil
        }

        // 3. Category names to CurseForge categoryIds (max 10)
        let categoryIds: [Int]?
        let allCategoryNames: [String]
        if projectType.lowercased() == "resourcepack" {
            // Resource packs: merge behavior and resolution categories
            allCategoryNames = categories + resolutions
        } else {
            allCategoryNames = categories
        }

        if !allCategoryNames.isEmpty {
            let mappedIds = mapToCurseForgeCategoryIds(
                modrinthCategoryNames: allCategoryNames,
                projectType: projectType
            )
            categoryIds = mappedIds.isEmpty ? nil : mappedIds
        } else {
            categoryIds = nil
        }

        // 4. Loader names to CurseForge ModLoaderType (max 5)
        let modLoaderTypes: [Int]?
        let lowercasedType = projectType.lowercased()
        if lowercasedType == "resourcepack" || lowercasedType == "shader" || lowercasedType == "datapack" {
            // These types do not support modLoaderType filtering on CurseForge
            modLoaderTypes = nil
        } else if !loaders.isEmpty {
            let loaderTypes = loaders.compactMap { loaderName -> Int? in
                CurseForgeModLoaderType.from(loaderName)?.rawValue
            }
            modLoaderTypes = loaderTypes.isEmpty ? nil : Array(loaderTypes.prefix(5))
        } else {
            modLoaderTypes = nil
        }

        // 5. Search filter: treat empty string as unset; otherwise pass through as-is
        let searchFilter = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSearchFilter = searchFilter.isEmpty ? nil : searchFilter

        return SearchParams(
            classId: classId,
            categoryIds: categoryIds,
            gameVersions: gameVersions,
            searchFilter: normalizedSearchFilter,
            modLoaderTypes: modLoaderTypes
        )
    }

    // MARK: - ProjectType -> classId

    /// Returns the CurseForge classId for a given project type string.
    private static func classIdForProjectType(_ projectType: String) -> Int? {
        switch projectType.lowercased() {
        case "mod":
            return CurseForgeClassId.mods.rawValue
        case "modpack":
            return CurseForgeClassId.modpacks.rawValue
        case "resourcepack":
            return CurseForgeClassId.resourcePacks.rawValue
        case "shader":
            return CurseForgeClassId.shaders.rawValue
        case "datapack":
            return CurseForgeClassId.datapacks.rawValue
        default:
            return nil
        }
    }

    // MARK: - Category Mapping (Modrinth -> CurseForge)

    /// Maps multiple Modrinth category names to CurseForge category IDs.
    /// - Parameters:
    ///   - modrinthCategoryNames: The list of Modrinth category names.
    ///   - projectType: The project type (e.g. `"mod"`, `"modpack"`, `"resourcepack"`, `"shader"`, `"datapack"`).
    /// - Returns: An array of CurseForge category IDs (capped at 10 per API limit).
    private static func mapToCurseForgeCategoryIds(
        modrinthCategoryNames: [String],
        projectType: String
    ) -> [Int] {
        let mappedIds = modrinthCategoryNames.compactMap { name in
            mapToCurseForgeCategoryId(
                modrinthCategoryName: name,
                projectType: projectType
            )
        }
        return Array(mappedIds.prefix(10))
    }

    /// Maps a single Modrinth category name to a CurseForge category ID.
    private static func mapToCurseForgeCategoryId(
        modrinthCategoryName: String,
        projectType: String
    ) -> Int? {
        let key = modrinthCategoryName.lowercased()
        switch projectType.lowercased() {
        case "mod", "modpack":
            return modCategoryMap[key]
        case "resourcepack":
            return resourcepackCategoryMap[key]
        case "shader":
            return shaderCategoryMap[key]
        case "datapack":
            return datapackCategoryMap[key]
        default:
            return nil
        }
    }

    // MARK: - Mod Category Mapping Table

    /// Modrinth mod/modpack category to CurseForge category ID mapping.
    /// Based on automated results from `gen_category_mapping.py` plus manual approximations.
    private static let modCategoryMap: [String: Int] = [
        "adventure": 422,       // Adventure and RPG
        "cursed": 425,          // Miscellaneous
        "decoration": 424,      // Cosmetic
        "economy": 425,         // Miscellaneous
        "equipment": 434,       // Armor, Tools, and Weapons
        "food": 436,            // Food
        "game-mechanics": 425,  // Miscellaneous
        "library": 421,         // API and Library
        "magic": 419,           // Magic
        "management": 435,      // Server Utility
        "minigame": 425,        // Miscellaneous
        "mobs": 411,            // Mobs
        "optimization": 6814,   // Performance
        "social": 5191,         // Utility & QoL
        "storage": 420,         // Storage
        "technology": 412,      // Technology
        "transportation": 414,  // Player Transport
        "utility": 435,         // Server Utility
        "worldgen": 406         // World Gen
    ]

    // MARK: - Resource Pack Category Mapping Table

    /// Modrinth resourcepack category to CurseForge category ID mapping.
    /// Based on automated results from `gen_category_mapping.py` plus manual approximations.
    private static let resourcepackCategoryMap: [String: Int] = [
        // Resolution mappings
        "128x": 396,
        "16x": 393,
        "256x": 397,
        "32x": 394,
        "64x": 395,
        "48x": 395,
        "512x+": 398,           // 512x and Higher
        "8x-": 393,             // Falls back to 16x
        // Style mappings
        "realistic": 400,       // Photo Realistic
        "simplistic": 403,      // Traditional
        "themed": 399,          // Steampunk
        "vanilla-like": 403,    // Traditional
        // Content / feature categories
        "audio": 405,
        "blocks": 405,
        "combat": 405,
        "core-shaders": 404,    // Animated
        "cursed": 405,
        "decoration": 405,
        "entities": 405,
        "environment": 405,
        "equipment": 405,
        "gui": 401,             // Modern
        "items": 405,
        "locale": 405,
        "models": 405,
        "tweaks": 405,
        "utility": 405,
        // Special cases
        "fonts": 5244,          // Font Packs
        "modded": 4465          // Mod Support
    ]

    // MARK: - Shader Category Mapping Table

    /// Modrinth shader category to CurseForge category ID mapping.
    /// CurseForge only offers Fantasy / Realistic / Vanilla, so approximations are used.
    private static let shaderCategoryMap: [String: Int] = [
        // Style / quality
        "fantasy": 6554,
        "realistic": 6553,
        "semi-realistic": 6553,
        "vanilla-like": 6555,
        // Additional tags
        "atmosphere": 6553,
        "bloom": 6553,
        "cartoon": 6554,
        "colored-lighting": 6553,
        "cursed": 6554,
        "foliage": 6553,
        "high": 6553,
        "low": 6555,
        "medium": 6555,
        "path-tracing": 6553,
        "pbr": 6553,
        "potato": 6555,
        "reflections": 6553,
        "screenshot": 6553,
        "shadows": 6553
    ]

    // MARK: - Datapack Category Mapping Table

    /// Modrinth datapack category to CurseForge category ID mapping.
    /// Datapacks reuse the same category keys as mods (adventure/magic/technology/...),
    /// mapped to CurseForge Data Packs (classId=6945) categories:
    /// - 6948 Adventure
    /// - 6949 Fantasy
    /// - 6950 Library
    /// - 6952 Magic
    /// - 6947 Miscellaneous
    /// - 6946 Mod Support
    /// - 6951 Tech
    /// - 6953 Utility
    private static let datapackCategoryMap: [String: Int] = [
        // Direct category matches
        "adventure": 6948,
        "library": 6950,
        "magic": 6952,
        "technology": 6951,
        "utility": 6953,

        // Semantic approximations
        "worldgen": 6948,         // Exploration/adventure-oriented
        "mobs": 6948,             // Mob spawning / events
        "optimization": 6953,     // Performance rules
        "storage": 6951,          // Storage / tech systems
        "management": 6953,       // Automation / utility
        "economy": 6953,          // Economy / currency rules
        "transportation": 6951,   // Teleport / transport

        // Remainder mapped to Miscellaneous
        "cursed": 6947,
        "decoration": 6947,
        "equipment": 6947,
        "food": 6947,
        "game-mechanics": 6947,
        "minigame": 6947,
        "social": 6947
    ]
}
