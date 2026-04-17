# nu-doc-gen

This is a simple Nu module to generate markdown documentation for Nu modules.

You can see the example on itself in [docs/nu-doc-gen.md](docs/nu-doc-gen.md).

## Commands

- `generate-module-docs <module_name> <output_file?>`
  Generates markdown from a module that is already loaded in scope.
- `generate-source-docs <module_path?> <output_file?>`
  Loads `.nu` source files from a module repo, groups multi-file modules by file, and generates markdown.
- `generate-doc-site <module_path?> <output_dir?>`
  Builds a static HTML/CSS/JS documentation site from a module repo. Each `.nu` file becomes a category when the module has more than just `mod.nu`.

For a multi-file module repo, run the source-aware commands from the repo root or point them at the module directory:

```nu
use nu-doc-gen *

generate-source-docs nu-salesforce/nu-salesforce nu-salesforce.md
generate-doc-site nu-salesforce/nu-salesforce site
```

## Installation

I recommend using [Quiver](https://github.com/freepicheep/quiver). If you have quiver installed, add this to your project with `qv add freepicheep/nu-doc-gen`. You can also install it globally with `qv add -g freepicheep/nu-doc-gen` and follow the instructions for adding the module to your `$env.NU_LIB_DIRS` so you can use it at any time.

## Examples

- I built documentation for nu-doc-gen using itself. :) It's [here](https://freepicheep.github.io/nu-doc-gen/).
- A more robust example for a Salesforce api wrapper: [nu-salesforce](https://freepicheep.github.io/nu-salesforce/)
