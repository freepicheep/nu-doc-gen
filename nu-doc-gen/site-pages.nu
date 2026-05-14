# HTML page builders for the generated documentation site, including navigation and search metadata.

use text.nu [ count-label html-escape render-doc-text-html ]
use command-doc.nu [ render-command-html ]

export def render-site-shell [
    site_title: string
    site_summary: string
    page_title: string
    page_lead: string
    site_version: string
    css_version: string
    theme_config_json: string
    nav_html: string
    search_index_json: string
    body_html: string
]: nothing -> string {
    let summary_html = if (($site_summary | str trim) == '') { '' } else { $"<p class=\"site-summary\">(html-escape $site_summary)</p>" }
    let lead_html = if (($page_lead | str trim) == '') { '' } else { $"<p class=\"page-lead\">(html-escape $page_lead)</p>" }
    let title_html = (html-escape $page_title)
    let version_html = if (($site_version | str trim) == '') {
        ''
    } else {
        $"<span class=\"site-version\">v(html-escape $site_version)</span>"
    }
    let css_href = if (($css_version | str trim) == '') {
        'assets/site.css'
    } else {
        $"assets/site.css?v=(html-escape $css_version)"
    }
    let theme_css_href = if (($css_version | str trim) == '') {
        'assets/theme.css'
    } else {
        $"assets/theme.css?v=(html-escape $css_version)"
    }
    let theme_bootstrap = '<script>
    (() => {
      try {
        const theme = localStorage.getItem("nu-doc-gen.theme");
        if (theme === "light" || theme === "dark") {
          document.documentElement.dataset.theme = theme;
        }
      } catch {
      }
    })();
  </script>'

    $"<!doctype html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>($title_html)</title>
  <meta name=\"description\" content=\"(html-escape $page_lead)\">
  ($theme_bootstrap)
  <link rel=\"stylesheet\" href=\"($css_href)\">
  <link rel=\"stylesheet\" href=\"($theme_css_href)\">
</head>
<body>
  <div class=\"layout\">
    <aside class=\"sidebar\">
      <div class=\"sidebar-header\">
        <p class=\"eyebrow\">Nu Module Docs</p>
        <h1 class=\"site-title\">(html-escape $site_title)($version_html)</h1>
        ($summary_html)
      </div>
      <button class=\"sidebar-toggle\" data-nav-toggle>Sections</button>
      <div class=\"sidebar-nav\" data-nav>
        <div class=\"nav-search-wrap\">
          <input class=\"nav-search\" type=\"search\" placeholder=\"Filter categories or commands\" autocomplete=\"off\" spellcheck=\"false\" data-nav-search>
          <div class=\"nav-search-dropdown\" hidden data-search-dropdown></div>
        </div>
        ($nav_html)
      </div>
    </aside>
    <div class=\"content-wrap\">
      <header class=\"page-header\">
        <div class=\"page-header-inner\">
          <h1 class=\"page-title\">($title_html)</h1>
          ($lead_html)
        </div>
      </header>
      <main class=\"page-content\">
        ($body_html)
      </main>
    </div>
  </div>
  <div class=\"theme-picker\" data-theme-picker>
    <div class=\"theme-menu\" role=\"menu\" hidden data-theme-menu>
      <button class=\"theme-choice\" type=\"button\" role=\"menuitemradio\" data-theme-choice=\"system\">
        <span class=\"theme-choice-icon theme-icon-system\" aria-hidden=\"true\"></span>
        <span>System</span>
      </button>
      <button class=\"theme-choice\" type=\"button\" role=\"menuitemradio\" data-theme-choice=\"light\">
        <span class=\"theme-choice-icon theme-icon-light\" aria-hidden=\"true\"></span>
        <span>Light</span>
      </button>
      <button class=\"theme-choice\" type=\"button\" role=\"menuitemradio\" data-theme-choice=\"dark\">
        <span class=\"theme-choice-icon theme-icon-dark\" aria-hidden=\"true\"></span>
        <span>Dark</span>
      </button>
    </div>
    <button class=\"theme-toggle\" type=\"button\" aria-label=\"Choose color theme\" aria-haspopup=\"menu\" aria-expanded=\"false\" data-theme-toggle data-theme-mode=\"system\">
      <span class=\"theme-toggle-icon\" aria-hidden=\"true\" data-theme-toggle-icon></span>
      <span data-theme-toggle-label>Theme</span>
    </button>
  </div>
  <script type=\"application/json\" id=\"theme-config\">($theme_config_json)</script>
  <script type=\"application/json\" id=\"search-index\">($search_index_json)</script>
  <script src=\"assets/fuse.min.js\"></script>
  <script type=\"module\" src=\"assets/site.js\"></script>
</body>
</html>"
}

export def render-search-index-json [model: record] {
    let records = (
        $model.categories
        | each {|category|
            let category_record = {
                kind: 'category'
                title: $category.title
                category: $category.title
                summary: ($category.summary | default '')
                url: $"($category.slug).html"
                file: ($category.file | path basename)
            }
            let command_records = (
                $category.commands
                | each {|command|
                    {
                        kind: 'command'
                        title: $command.name
                        category: $category.title
                        summary: ($command.description | default '')
                        url: $"($category.slug).html#($command.slug)"
                        file: ($category.file | path basename)
                    }
                }
            )

            [$category_record] | append $command_records
        }
        | flatten
    )

    $records
    | to json --raw
    | str replace --all '</' '<\/'
}

export def render-nav-html [model: record current_slug?: string] {
    let overview_active = if ($current_slug | default '') == '' { ' is-active' } else { '' }
    let category_links = (
        $model.categories
        | each {|category|
            let category_search = ([$category.title $category.summary ($category.commands | get name | str join ' ')] | str join ' ')
            let active_class = if ($current_slug | default '') == $category.slug { ' is-active' } else { '' }
            let subnav = if ($current_slug | default '') == $category.slug {
                let items = (
                    $category.commands
                    | each {|command|
                        $"<li data-command-item data-search=\"(html-escape $command.name)\"><a class=\"nav-link\" data-command-link href=\"($category.slug).html#($command.slug)\">(html-escape $command.name)</a></li>"
                    }
                    | str join "\n"
                )
                if (($category.commands | length) == 0) {
                    ''
                } else {
                    $"<ul class=\"nav-sublist\">\n($items)\n</ul>"
                }
            } else {
                ''
            }

            $"<li data-category-item data-search=\"(html-escape $category_search)\">
  <a class=\"nav-link($active_class)\" href=\"($category.slug).html\">(html-escape $category.title)</a>
  ($subnav)
</li>"
        }
        | str join "\n"
    )

    $"<p class=\"nav-group-title\">Overview</p>
<ul class=\"nav-list\">
  <li><a class=\"nav-link($overview_active)\" href=\"index.html\">Introduction</a></li>
</ul>
<p class=\"nav-group-title\">Categories</p>
<ul class=\"nav-list\">($category_links)
</ul>"
}

export def render-index-page [model: record theme_config_json: string] {
    let overview_items = if (($model.categories | length) == 0) {
        '<div class="empty-state">No exported commands were found.</div>'
    } else {
        $model.categories
        | each {|category|
            let desc = if (($category.description | default '' | str trim) == '') {
                '<p class="overview-desc">No module description available.</p>'
            } else {
                $"<div class=\"overview-desc\">(render-doc-text-html $category.description)</div>"
            }
            let exported_count = ($category.commands | where is_exported == true | length)
            let internal_count = ($category.commands | where is_exported == false | length)
            let exported_label = (count-label $exported_count 'exported command' 'exported commands')
            let internal_label = (count-label $internal_count 'internal command' 'internal commands')
            let meta = if $internal_count == 0 {
                $exported_label
            } else {
                $"($exported_label), ($internal_label)"
            }
            $"<article class=\"overview-item\">
  <h2>(html-escape $category.title)</h2>
  <p class=\"overview-meta\">($meta)</p>
  ($desc)
  <a class=\"overview-link\" href=\"($category.slug).html\">Open category</a>
</article>"
        }
        | str join "\n"
    }

    let lead = if (($model.summary | str trim) == '') {
        'Generated from Nushell source files and command help.'
    } else {
        $model.summary
    }

    let strip = [
        $"<span class=\"summary-pill\">(count-label $model.total_commands 'total command' 'total commands')</span>"
        $"<span class=\"summary-pill\">(count-label ($model.exported_commands | length) 'exported command' 'exported commands')</span>"
        $"<span class=\"summary-pill\">(count-label $model.internal_commands 'internal command' 'internal commands')</span>"
        $"<span class=\"summary-pill\">(count-label ($model.categories | length) 'category' 'categories')</span>"
        $"<span class=\"summary-pill\">Source mode: (if $model.source_mode { 'multi-file' } else { 'single-file' })</span>"
    ] | str join "\n"

    let body = $"<div class=\"summary-strip\">($strip)</div>
<section class=\"overview-list\">($overview_items)
</section>"

    render-site-shell $model.name $model.summary_short $model.name $lead ($model.package_version? | default '') ($model.nu_doc_gen_version? | default '') $theme_config_json (render-nav-html $model) (render-search-index-json $model) $body
}

export def render-category-page [model: record category: record theme_config_json: string] {
    let lead = if (($category.summary | str trim) == '') {
        $'Commands exported from ($category.file | path basename).'
    } else {
        $category.summary
    }
    let exported_count = ($category.commands | where is_exported == true | length)
    let internal_count = ($category.commands | where is_exported == false | length)
    let strip = [
        $"<span class=\"summary-pill\">File: <code>(html-escape ($category.file | path basename))</code></span>"
        $"<span class=\"summary-pill\">(count-label $exported_count 'exported command' 'exported commands')</span>"
        $"<span class=\"summary-pill\">(count-label $internal_count 'internal command' 'internal commands')</span>"
    ] | str join "\n"

    let sections = if (($category.commands | length) == 0) {
        '<div class="empty-state">No exported commands were found in this file.</div>'
    } else {
        $category.commands
        | each {|command| render-command-html $command }
        | str join "\n"
    }

    let body = $"<div class=\"summary-strip\">($strip)</div>
<section class=\"command-stack\">($sections)
</section>"

    render-site-shell $model.name $model.summary_short $category.title $lead ($model.package_version? | default '') ($model.nu_doc_gen_version? | default '') $theme_config_json (render-nav-html $model $category.slug) (render-search-index-json $model) $body
}
