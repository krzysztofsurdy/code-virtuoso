# Visual baseline

Set these before building content, then screenshot and compare. Defaults produce flat, clipped images, and fixing them late changes every asset's look. Defaults below were read from the 4.6.1 class reference and the official pages named.

## Contents

- [3D environment](#3d-environment)
- [2D lighting](#2d-lighting)
- [Pixel art](#pixel-art)
- [Check](#check)

## 3D environment

Add a `WorldEnvironment` with an `Environment` resource, and one `DirectionalLight3D`.

| Setting | Notes |
|---|---|
| `tonemap_mode` | Default is Linear, which clips bright values ([Environment](https://docs.godotengine.org/en/stable/classes/class_environment.html)). Choices: Linear, Reinhard, Filmic, ACES, AgX. ACES is high contrast and desaturates brights. AgX is an adjustable film-like curve (`tonemap_agx_contrast` default 1.25, `tonemap_agx_white` default 16.29). AgX arrived in 4.4, and 4.6 made its parameters configurable |
| `glow_enabled`, `glow_blend_mode` | In 4.6 the default blend mode changed from Soft Light to Screen, `glow_intensity` from 0.8 to 0.3, and glow is blended before tonemapping ([4.6 migration page](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html)). Before 4.6 glow ran after tonemapping, so values tuned on 4.5 look different. The class reference still describes Soft Light as applied to the tonemapped image, so look at the result instead of trusting the order |
| `glow_hdr_threshold` | With the Mobile renderer, which has lower dynamic range, glow may need a threshold below 1.0 to show |
| Ambient light | Set a sky or color source, not black |
| Volumetric fog | Brighter from 4.6 on (more physically accurate blending). Lower density or fog energy when upgrading |

Check every property name against the class reference for the project's version before writing it.

## 2D lighting

- `CanvasModulate` sets the ambient color of the whole 2D scene.
- `PointLight2D` with a radial `GradientTexture2D` for lamps, `DirectionalLight2D` for sun, `LightOccluder2D` for shadows.
- Add normal maps only if the art has them.

## Pixel art

| Setting | Value | Source |
|---|---|---|
| `rendering/textures/canvas_textures/default_texture_filter` | Nearest (default is Linear) | Project settings class reference |
| `display/window/stretch/mode` | `viewport` | [Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html). The default is `disabled` for projects created before 4.7. From 4.7, new projects start with `canvas_items` and aspect `expand` |
| `display/window/stretch/aspect` | `keep` for one aspect ratio, `expand` for several | Same page |
| `display/window/stretch/scale_mode` | `integer` (since 4.2). The default is `fractional` | Same page |
| Base window size | The low viewport size you design for, for example 320x180, with the window an integer multiple | Same page |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` and `snap_2d_vertices_to_pixel` | Consider turning both on. The first defaults to off | Project settings class reference |

Do not rotate or scale pixel sprites by non-integer values, and keep the camera on whole pixels.

## Check

Run the game, take a screenshot, and look at it: tonemap and glow set, no clipped whites, pixel art sharp with no shimmer when the camera moves. Keep one art style and resolution per project.
