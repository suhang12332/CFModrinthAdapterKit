# CFModrinthAdapterKit

一个纯数据层的 Swift Package，用于在 **CurseForge** 与 **Modrinth** 的数据结构/搜索参数之间做适配与转换。

## 功能

- **CurseForge → Modrinth**
  - 将 CurseForge 项目详情/文件详情/搜索结果转换为 Modrinth 对应结构
  - 入口：`CFToModrinthAdapter`
- **Modrinth → CurseForge（搜索）**
  - 将 Modrinth 风格的搜索参数映射为 CurseForge API 可用的搜索参数
  - 入口：`ModrinthToCurseForgeSearchAdapter`

## 环境要求

- Swift tools version：6.1（见 `Package.swift`）

## 安装（Swift Package Manager）

在 Xcode 里添加 Package Dependency，指向本仓库地址；或在 `Package.swift` 中加入依赖（示例中的 URL 请替换为你的仓库地址）：

```swift
.package(url: "https://example.com/CFModrinthAdapterKit.git", from: "0.1.0")
```

然后在 target 里添加：

```swift
.product(name: "CFModrinthAdapterKit", package: "CFModrinthAdapterKit")
```

## 使用示例

### CurseForge → Modrinth

```swift
import CFModrinthAdapterKit

let modrinthDetail = CFToModrinthAdapter.convertProjectDetail(cfDetail, descriptionHTML: html)
let modrinthVersion = CFToModrinthAdapter.convertFile(cfFileDetail, projectId: "cf-\(cfProjectId)")
let modrinthSearch = CFToModrinthAdapter.convertSearchResult(cfSearchResult)
```

### Modrinth 搜索参数 → CurseForge 搜索参数

```swift
import CFModrinthAdapterKit

let params = ModrinthToCurseForgeSearchAdapter.convertToSearchParams(
    projectType: "mod",
    versions: ["1.20.1"],
    categories: ["technology"],
    resolutions: [],
    loaders: ["fabric"],
    query: "sodium"
)

// params.classId / params.categoryIds / params.gameVersions / params.modLoaderTypes / params.searchFilter
// 可用于你自己的网络层去拼 CurseForge API 的查询字符串
```

## 说明

- 本包只负责“模型与参数的适配/转换”，不包含具体网络请求实现。
