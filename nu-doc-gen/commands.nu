# Exported commands for generating module docs, source-based docs, static doc sites, and pager views.

use help-doc.nu [parse-help-doc render-command-markdown]
use module-source.nu [collect-module-doc-model]
use plugin-runtime.nu [collect-plugin-doc-model]
use site-assets.nu [site-css site-js]
use site-pages.nu [render-index-page render-category-page]
use site-theme.nu [resolve-site-theme-pair site-theme-css site-theme-config-json]

const vendored_fuse_asset = ([((path self) | path dirname) 'vendor' 'fuse.min.js'] | path join)

# Generate markdown documentation for the specified module already loaded in scope.
@example "Generate docs for nu-salesforce" { generate-module-docs nu-salesforce nu-salesforce.md }
export def generate-module-docs [
    module_name: string # the module to generate docs for
    output_file: string = 'docs.md' # the output file
] {
    '' | save --force $output_file
    $"# ($module_name) — Module Reference\n\n" | save --append $output_file

    let commands = (
        scope modules
        | where name == $module_name
        | get commands
        | flatten
        | get name
    )

    if (($commands | length) == 0) {
        error make {msg: $'No module named ''($module_name)'' found in scope.'}
    }

    print $'Generating docs for ($commands | length) commands in ($module_name)...'

    $commands | each {|command_name|
        print $'  -> ($command_name)'
        let doc = (help $command_name | ansi strip | parse-help-doc $command_name)
        $"(render-command-markdown $doc)\n\n---\n\n" | save --append $output_file
    }

    print $'\nDone! Docs written to: ($output_file)'
}

# Generate markdown documentation by loading source files from a module repo.
@example "Generate source-aware docs for nu-salesforce" { generate-source-docs nu-salesforce/nu-salesforce nu-salesforce.md }
export def generate-source-docs [
    module_path: string = '.' # module directory or mod.nu path
    output_file: string = 'docs.md' # the output file
] {
    let model = (collect-module-doc-model $module_path)

    '' | save --force $output_file
    $"# ($model.name) — Module Reference\n\n" | save --append $output_file

    if (($model.summary | str trim) != '') {
        $"($model.summary)\n\n" | save --append $output_file
    }

    $model.categories | each {|category|
        $"## ($category.title)\n\n" | save --append $output_file

        if (($category.summary | str trim) != '') {
            $"($category.summary)\n\n" | save --append $output_file
        }

        $category.commands | each {|command|
            $"(render-command-markdown $command)\n\n---\n\n" | save --append $output_file
        }
    }

    print $'Done! Docs written to: ($output_file)'
}

# Generate a static documentation site by loading source files from a module repo.
@example "Generate a static site for nu-salesforce" { generate-doc-site nu-salesforce/nu-salesforce site }
export def generate-doc-site [
    module_path: string = '.' # module directory or mod.nu path
    output_dir: string = 'site' # the directory to write the static site into
    --light-theme: string = 'rose-pine-dawn' # bundled Shiki light theme name from themes.toml
    --dark-theme: string = 'rose-pine' # bundled Shiki dark theme name from themes.toml
] {
    let model = (collect-module-doc-model $module_path)
    let theme_pair = (resolve-site-theme-pair $light_theme $dark_theme)
    let theme_config_json = (site-theme-config-json $theme_pair)
    let site_dir = ($output_dir | path expand)
    let assets_dir = ([$site_dir 'assets'] | path join)

    mkdir $site_dir
    mkdir $assets_dir

    if not ($vendored_fuse_asset | path exists) {
        error make {
            msg: $'Missing vendored Fuse asset at ($vendored_fuse_asset).'
        }
    }

    (site-css) | save --force ([$assets_dir 'site.css'] | path join)
    (site-theme-css $theme_pair) | save --force ([$assets_dir 'theme.css'] | path join)
    (site-js) | save --force ([$assets_dir 'site.js'] | path join)
    (open --raw $vendored_fuse_asset) | save --force ([$assets_dir 'fuse.min.js'] | path join)
    (render-index-page $model $theme_config_json) | save --force ([$site_dir 'index.html'] | path join)

    $model.categories | each {|category|
        (render-category-page $model $category $theme_config_json) | save --force ([$site_dir $"($category.slug).html"] | path join)
    }

    print $'Done! Static site written to: ($site_dir)'
}

# Generate a static documentation site for an already-loaded Nushell plugin.
@example "Generate a static site for a loaded plugin" { generate-plugin-doc-site polars site }
export def generate-plugin-doc-site [
    plugin_name: string # loaded plugin name from `plugin list`
    output_dir: string = 'site' # the directory to write the static site into
    --light-theme: string = 'rose-pine-dawn' # bundled Shiki light theme name from themes.toml
    --dark-theme: string = 'rose-pine' # bundled Shiki dark theme name from themes.toml
    --exclude-plugin-command # omit the command whose name exactly matches the plugin name
] {
    let model = (collect-plugin-doc-model $plugin_name $exclude_plugin_command)
    let theme_pair = (resolve-site-theme-pair $light_theme $dark_theme)
    let theme_config_json = (site-theme-config-json $theme_pair)
    let site_dir = ($output_dir | path expand)
    let assets_dir = ([$site_dir 'assets'] | path join)

    mkdir $site_dir
    mkdir $assets_dir

    if not ($vendored_fuse_asset | path exists) {
        error make {
            msg: $'Missing vendored Fuse asset at ($vendored_fuse_asset).'
        }
    }

    (site-css) | save --force ([$assets_dir 'site.css'] | path join)
    (site-theme-css $theme_pair) | save --force ([$assets_dir 'theme.css'] | path join)
    (site-js) | save --force ([$assets_dir 'site.js'] | path join)
    (open --raw $vendored_fuse_asset) | save --force ([$assets_dir 'fuse.min.js'] | path join)
    (render-index-page $model $theme_config_json) | save --force ([$site_dir 'index.html'] | path join)
    if (($model.kind? | default '') != 'plugin') {
        $model.categories | each {|category|
            (render-category-page $model $category $theme_config_json) | save --force ([$site_dir $"($category.slug).html"] | path join)
        }
    }

    print $'Done! Static site written to: ($site_dir)'
}

# Quickly view all the exported commands for a given module in your default pager.
@example "view the docs for nu-salesforce" { view-docs nu-salesforce }
export def view-docs [
    module_name: string # the module you want to explore
] {
    let docs = (
        scope modules
        | where name == $module_name
        | get commands
        | flatten
        | get name
        | each { $"($in)\n\n(help $in)------------------\n\n" }
        | str join
    )

    let pager_cmd = ($env.PAGER | split row ' ')
    let executable = ($pager_cmd | first)
    let args = ($pager_cmd | drop nth 0)

    $docs | ^$executable ...$args
}
