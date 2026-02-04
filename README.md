# kra_importer

Import `.kra` files directly into Godot - no export needed.

## Installation

1. Copy `kra_importer` to your projects addons folder.
2. Enable in Project Settings → Plugins

## Usage

Drag `.kra` files into your project. They import like any other texture.

## Import Options

- **Compress/Mode** - Texture compression type
- **Mipmaps/Generate** - Create mipmaps for 3D
- **Process/Premult Alpha** - Premultiply alpha channel

## Notes

Uses Krita's flattened preview image. Only works with Godot 4.x.

If your `.kra` has animation frames, the imported texture will be whichever
frame was visible when you last saved the file in Krita.
