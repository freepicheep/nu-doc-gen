# nu-doc-gen

This is a simple Nu module to generate markdown documentation and static sites for Nu modules.

## Commands

- `generate-module-docs <module_name> <output_file?>`
  Generates markdown from a module that is already loaded in scope.
- `generate-source-docs <module_path?> <output_file?>`
  Loads `.nu` source files from a module repo, groups multi-file modules by file, and generates markdown.
- `generate-doc-site <module_path?> <output_dir?> --light-theme <shiki_theme?> --dark-theme <shiki_theme?>`
  Builds a static HTML/CSS/JS documentation site from a module repo. Each `.nu` file becomes a category when the module has more than just `mod.nu`. Light and dark site palettes come from the bundled `nu-doc-gen/themes.toml` registry, which maps supported Shiki themes to bundled Ghostty color schemes.

For a multi-file module repo, run the source-aware commands from the repo root or point them at the module directory:

```nu
use nu-doc-gen *

generate-source-docs nu-salesforce/nu-salesforce nu-salesforce.md
generate-doc-site nu-salesforce/nu-salesforce site
generate-doc-site nu-salesforce/nu-salesforce site --light-theme github-light-default --dark-theme github-dark-default
```

## Installation

I recommend using [Quiver](https://github.com/freepicheep/quiver). If you have quiver installed, add this to your project with `qv add freepicheep/nu-doc-gen`. You can also install it globally with `qv add -g freepicheep/nu-doc-gen` and follow the instructions for adding the module to your `$env.NU_LIB_DIRS` so you can use it at any time.

## Auto Deploy Using GitHub Actions

Thanks to Quiver's new `qvx` mode, you can use `nu-doc-gen` as a GitHub action to automatically deploy your module's docs to a GitHub page.

```yaml
name: Deploy Docs

on:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: github-pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Install Quiver
        run: curl --proto '=https' --tlsv1.2 -LsSf https://github.com/freepicheep/quiver/releases/latest/download/quiver-installer.sh | sh

      - name: Add Quiver to PATH
        run: echo "$HOME/.local/bin" >> "$GITHUB_PATH"

      - name: Build documentation site
        run: qvx freepicheep/nu-doc-gen generate-doc-site "${{ github.event.repository.name }}/" site/

      - name: Upload Pages artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: site

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build

    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

## Examples

- I built documentation for nu-doc-gen using itself. :) It's [here](https://freepicheep.github.io/nu-doc-gen/).
- A more robust example for a Salesforce api wrapper: [nu-salesforce](https://freepicheep.github.io/nu-salesforce/)

## Credit

- I used LLMs extensively to help with the project.
- The wonderful [Shiki](https://shiki.style/) project for Nu code block highlighting.
- The wonderful [Fuse.js](https://www.fusejs.io/) for search.
