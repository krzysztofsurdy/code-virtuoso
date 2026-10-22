# Editing .tscn and .tres as text

Use the editor or an MCP scene tool when you can. Edit text when a change is small and mechanical, such as a path fix after a rename or a property value. Facts below come from the [TSCN file format](https://docs.godotengine.org/en/stable/engine_details/file_formats/tscn.html) page and from runs on 4.6.1.

## Rules

| Rule | Why |
|---|---|
| Every `ExtResource("id")` and `SubResource("id")` must match an `id` declared in the same file | A dangling id fails the load with `Parse error` and a line number |
| Declare a resource before the line that refers to it | The loader reads top to bottom, and the format page says the referring resource must appear after |
| Keep ids unique per kind. An external and an internal resource may share an id | The format allows it, but unique ids are easier to read |
| `ext_resource` carries `type`, `path`, `uid`, `id`. `sub_resource` has no `uid` | Do not invent a `uid="uid://..."`. Leave it out and let the editor assign one on save |
| Paths start with `res://` | Relative paths are valid, but the editor writes absolute ones, so matching them keeps diffs small |
| `load_steps` is ignored from 4.6. Do not add it, and leave it alone if present | The format page marks it deprecated |
| Do not hand-write `unique_id` on nodes | It exists only in scenes saved by 4.6 or later, and the editor manages it |
| Comments and properties equal to their default are dropped when the editor saves | Do not put information in them |
| Header `format=3` is Godot 4 | `format=2` is Godot 3 |

## After an edit

1. Run the import, then load the scene: `godot --headless --path <dir> --quit-after 2 res://scene.tscn`. Read the output for `Parse error`, `Failed loading resource`, and `non-existent resource`.
2. Run the verify loop from the `godot` skill.
3. If the file was moved or renamed, search the project for the old `res://` path in `.tscn`, `.tres`, `.gd`, and `project.godot`.

## Editor rewrites

Saving a scene in a 4.6 or later editor drops `load_steps` and adds node `unique_id` values, so the first save of an older scene is a large diff. The official 4.6 page recommends running Project > Tools > Upgrade Project Files once, in its own commit, so later diffs stay small. Scripts and shaders get `.uid` files from 4.4 on, and `@export_file` values are stored as `uid://` references from 4.4 on. See the `godot-upgrade` skill.
