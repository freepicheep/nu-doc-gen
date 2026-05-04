# nu-doc-gen

This is a simple Nu module to generate static site and markdown documentation for Nu modules and loaded Nu plugins.

## Building a Static Site

Build a static HTML/CSS/JS documentation site from a module repo. Each `.nu` file becomes a category when the module has more than just `mod.nu`. Light and dark site palettes come from the bundled `nu-doc-gen/themes.toml` registry, which maps supported Shiki themes to bundled Ghostty color schemes.

```nushell
generate-doc-site <module_path?> <output_dir?> --light-theme <shiki_theme?> --dark-theme <shiki_theme?>
```

## Building a Plugin Site

Build a static HTML/CSS/JS documentation site from a plugin that is already loaded in the current Nu session. This path reads command names from `plugin list` and builds each command page from runtime `help` output, so source code access is not required.

```nushell
generate-plugin-doc-site <plugin_name> <output_dir?> --light-theme <shiki_theme?> --dark-theme <shiki_theme?>
```

If the plugin exposes a top-level command with the same name as the plugin and you want to omit it, add `--exclude-plugin-command`.

<details>
<summary>Supported Themes</summary>


| Theme | Shiki Name (use in command) | Mode |
| --- | --- | --- |
| Ayu Mirage | ayu-mirage | dark |
| Ayu | ayu-dark | dark |
| Andromeda | andromeeda | dark |
| Catppuccin Frappe | catppuccin-frappe | dark |
| Catppuccin Macchiato | catppuccin-macchiato | dark |
| Catppuccin Mocha | catppuccin-mocha | dark |
| Dark+ | dark-plus | dark |
| Dracula | dracula | dark |
| Everforest Dark Hard | everforest-dark | dark |
| GitHub Dark | github-dark | dark |
| GitHub Dark Default | github-dark-default | dark |
| GitHub Dark Dimmed | github-dark-dimmed | dark |
| GitHub Dark High Contrast | github-dark-high-contrast | dark |
| Gruvbox Dark Hard | gruvbox-dark-hard | dark |
| Gruvbox Dark | gruvbox-dark-medium | dark |
| Gruvbox Dark | gruvbox-dark-soft | dark |
| Horizon | horizon | dark |
| Kanagawa Dragon | kanagawa-dragon | dark |
| Kanagawa Wave | kanagawa-wave | dark |
| Material | material-theme | dark |
| Material Darker | material-theme-darker | dark |
| Material Ocean | material-theme-ocean | dark |
| Night Owl | night-owl | dark |
| Nord | nord | dark |
| Poimandres | poimandres | dark |
| Rose Pine | rose-pine | dark |
| Rose Pine Moon | rose-pine-moon | dark |
| Synthwave | synthwave-84 | dark |
| TokyoNight | tokyo-night | dark |
| Vesper | vesper | dark |
| Ayu Light | ayu-light | light |
| Catppuccin Latte | catppuccin-latte | light |
| Everforest Light Med | everforest-light | light |
| GitHub | github-light | light |
| GitHub Light Default | github-light-default | light |
| GitHub Light High Contrast | github-light-high-contrast | light |
| Gruvbox Light Hard | gruvbox-light-hard | light |
| Gruvbox Light | gruvbox-light-medium | light |
| Gruvbox Light | gruvbox-light-soft | light |
| Horizon Bright | horizon-bright | light |
| Kanagawa Lotus | kanagawa-lotus | light |
| Night Owlish Light | night-owl-light | light |
| Rose Pine Dawn | rose-pine-dawn | light |

</details>

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
        run: qvx freepicheep/nu-doc-gen generate-doc-site "${{ github.event.repository.name }}/"

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
- [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes) for the color palettes for the 43 supported themes.
