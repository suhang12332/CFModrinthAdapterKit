# CFModrinthAdapterKit

A pure data-layer Swift Package for adapting CurseForge and Modrinth models and search parameters. This package is used by [Swift Craft Launcher](https://github.com/suhang12332/Swift-Craft-Launcher).

## Features

- CurseForge project, file, and search results to Modrinth models
- Modrinth-style search parameters to CurseForge parameters
- CurseForge and Modrinth model definitions
- No networking logic

## Entry Points

- `CFToModrinthAdapter`: CurseForge to Modrinth conversion
- `ModrinthToCurseForgeSearchAdapter`: search parameter conversion
- `CurseForge*` and `Modrinth*`: shared data models

## Requirements

- Swift 6
