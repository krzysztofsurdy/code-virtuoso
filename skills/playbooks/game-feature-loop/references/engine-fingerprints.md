# Engine fingerprints

Step 1 of the loop. Find the engine from files, confirm the match is real, then read the version from its own source.

## Contents

- [Fingerprints and version sources](#fingerprints-and-version-sources)
- [Verify the match](#verify-the-match)
- [Ambiguity rules](#ambiguity-rules)
- [Other engines](#other-engines)

## Fingerprints and version sources

| Engine | Project fingerprint | Version source |
|---|---|---|
| Godot | `project.godot` at the project root | The version tag in the `config/features` line of `project.godot`, then the engine binary's `--version` output if you can run it |
| Unity | `Assets/` and `ProjectSettings/ProjectVersion.txt` together | `m_EditorVersion` in `ProjectSettings/ProjectVersion.txt`, plus package versions in `Packages/manifest.json` |
| Unreal | A `*.uproject` file at the project root | The `EngineAssociation` field in the `.uproject` file |
| Phaser, PixiJS, three.js | `package.json` listing `phaser`, `pixi.js`, or `three` as a dependency | The resolved version in the lockfile, not the range in `package.json` |
| Bevy | `Cargo.toml` listing `bevy` as a dependency | The resolved `bevy` entry in `Cargo.lock` |

The `EngineAssociation` value depends on the install. A launcher install usually holds a version such as `5.1`, a source build holds a GUID, and a project kept inside its engine tree can leave it empty. A GUID or an empty value does not tell you the version, so ask the user or read the installed engine.

`ProjectVersion.txt` holds two lines: `m_EditorVersion` and `m_EditorVersionWithRevision`.

Existing projects keep their detected version unless the user asks to migrate. Never move a project to a newer engine version to get an API you want.

## Verify the match

A fingerprint file proves little on its own. Check these before you rely on it:

1. Open the file. A `project.godot` or `.uproject` that parses and names a main scene or modules is a project. An empty or templated file may not be.
2. Check where it sits. A fingerprint inside `addons/`, `Packages/`, `node_modules/`, `Samples/`, or `third_party/` is a vendored sample, not the project being worked on.
3. For web engines, confirm the code imports the library. A `three` dependency in a marketing site is not a game project.
4. For Unity, require both `Assets/` and `ProjectSettings/ProjectVersion.txt`. A stray `.cs` file or `.csproj` alone does not identify Unity.
5. Read the README or the git history of the fingerprint file to see it belongs to the live project.

## Ambiguity rules

- A `project.godot` means Godot, even when a `.csproj` is present (Godot supports C#).
- A `package.json` may list more than one web engine. Use the one imported by the file under discussion. If unclear, ask.
- Several engines in one repository: route by the directory the request is about. If still unclear, ask one question.
- No project files but the user names an engine in the request: use that engine and say you are going by their word.
- No files and no named engine: ask. Do not default to a favorite.

## Other engines

For LÖVE, pygame, Roblox, and others, the router skill in the community gamedev library keeps a fuller fingerprint table with secondary signals (source: https://github.com/gamedev-skills/awesome-gamedev-agent-skills, file `router/references/engine-detection.md`). Treat any row you cannot open and confirm in the project the same way as the table above.
