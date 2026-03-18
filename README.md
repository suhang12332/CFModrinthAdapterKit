# CFModrinthAdapterKit

一个纯数据层的 Swift Package，用于在 **CurseForge** 与 **Modrinth** 的数据结构/搜索参数之间做适配与转换。

## 功能

- **CurseForge → Modrinth**
  - 将 CurseForge 项目详情/文件详情/搜索结果转换为 Modrinth 对应结构
  - 入口：`CFToModrinthAdapter`
- **Modrinth → CurseForge（搜索）**
  - 将 Modrinth 风格的搜索参数映射为 CurseForge API 可用的搜索参数
  - 入口：`ModrinthToCurseForgeSearchAdapter`


- 本包只负责“模型与参数的适配/转换”，不包含具体网络请求实现。 本包服务于 [Swift Craft Launcher](https://github.com/suhang12332/Swift-Craft-Launcher)
