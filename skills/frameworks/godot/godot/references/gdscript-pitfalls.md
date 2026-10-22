# GDScript pitfalls

Each row was checked on Godot 4.6.1 with a parse check, or comes from the official docs for the version named.

## Contents

- [Type inference](#type-inference)
- [Language behavior](#language-behavior)
- [Names that changed](#names-that-changed)

## Type inference

`:=` infers a type from the right side. It is an error when the right side has no static type.

| Code | Result on 4.6.1 | Fix |
|---|---|---|
| `var v := dict["k"]` | `Cannot infer the type of "v" variable because the value doesn't have a set type` | `var v: int = dict["k"]` |
| `var v := untyped_array[0]` | Same error | Type the array: `var a: Array[int]`, then `var v := a[0]` works |
| `var j := JSON.parse_string(s)` | `The variable type is being inferred from a Variant value` (warning treated as error by default) | `var j: Variant = JSON.parse_string(s)`, then check its type |
| `var n := get_node("X")` | Works, typed as `Node` | Cast for a subtype: `var s: Sprite2D = get_node("X")` |
| `var r := load("res://a.tres")` | Works, typed as `Resource` | Annotate the real type |
| `Array[Array[int]]`, `Dictionary[String, Dictionary[String, int]]` | Nested typed collections are not supported ([static typing docs](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html)) | Use an untyped inner collection or a small class |

The untyped-declaration warning is off by default. Turn on `UNTYPED_DECLARATION` in Project Settings under Debug > GDScript (Advanced Settings on) to find the gaps.

## Language behavior

| Pitfall | Detail |
|---|---|
| `assert` | Ignored in non-debug builds, and it pauses a project run from the editor ([GDScript basics](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)). Never use it for logic with side effects. For test runners see [headless-testing](headless-testing.md) |
| `@export` plus `@onready` on one variable | Does not work as expected, per the GDScript basics page. Use one or the other |
| Override of a method that has a typed return (4.7 and later) | The override inherits the return type and needs an explicit `return`. Add `return null` where the base returns an object ([4.7 migration page](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)) |
| Lifecycle overrides call `super()` explicitly | Godot 4 does not call the parent version for you ([3 to 4 page](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.html)) |
| Assigning one element of a packed array (4.7 and later) | No longer calls the setter for the whole array property |
| `await` on a coroutine | The caller continues immediately unless it also awaits. A function containing `await` is a coroutine |
| `Resource.duplicate(true)` (4.5 and later) | Duplicates only resources internal to the file. Use `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` for the 4.4 behavior |

## Names that changed

Godot 3 names the model still writes: `yield`, `KinematicBody`, `export var`, `onready`, `.instance()`, `connect("sig", self, "fn")`, `str2var` (now `str_to_var`). The official [3 to 4 page](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.html) lists the renames and the `--convert-3to4` tool. When a name fails to parse, dump the real signatures (see the `godot` skill) instead of guessing a rename.
