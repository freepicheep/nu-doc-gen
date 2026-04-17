use text.nu [html-escape]
use help-doc.nu [render-command-html]

export def render-site-shell [
    site_title: string
    site_summary: string
    page_title: string
    page_lead: string
    nav_html: string
    search_index_json: string
    body_html: string
]: nothing -> string {
    let summary_html = if (($site_summary | str trim) == '') { '' } else { $"<p class=\"site-summary\">(html-escape $site_summary)</p>" }
    let lead_html = if (($page_lead | str trim) == '') { '' } else { $"<p class=\"page-lead\">(html-escape $page_lead)</p>" }
    let title_html = (html-escape $page_title)

    [
        '<!doctype html>'
        '<html lang="en">'
        '<head>'
        '  <meta charset="utf-8">'
        '  <meta name="viewport" content="width=device-width, initial-scale=1">'
        $"  <title>($title_html)</title>"
        $"  <meta name=\"description\" content=\"(html-escape $page_lead)\">"
        '  <link rel="stylesheet" href="assets/site.css">'
        '</head>'
        '<body>'
        '  <div class="layout">'
        '    <aside class="sidebar">'
        '      <div class="sidebar-header">'
        '        <p class="eyebrow">Nu Module Docs</p>'
        $"        <h1 class=\"site-title\">(html-escape $site_title)</h1>"
        $'        ($summary_html)'
        '      </div>'
        '      <button class="sidebar-toggle" data-nav-toggle>Sections</button>'
        '      <div class="sidebar-nav" data-nav>'
        '        <div class="nav-search-wrap">'
        '          <input class="nav-search" type="search" placeholder="Filter categories or commands" autocomplete="off" spellcheck="false" data-nav-search>'
        '          <div class="nav-search-dropdown" hidden data-search-dropdown></div>'
        '        </div>'
        $"        ($nav_html)"
        '      </div>'
        '    </aside>'
        '    <div class="content-wrap">'
        '      <header class="page-header">'
        '        <div class="page-header-inner">'
        $"          <h1 class=\"page-title\">($title_html)</h1>"
        $'          ($lead_html)'
        '        </div>'
        '      </header>'
        '      <main class="page-content">'
        $"        ($body_html)"
        '      </main>'
        '    </div>'
        '  </div>'
        $"  <script type=\"application/json\" id=\"search-index\">($search_index_json)</script>"
        '  <script src="assets/fuse.min.js"></script>'
        '  <script type="module" src="assets/site.js"></script>'
        '</body>'
        '</html>'
    ] | str join "\n"
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

export def render-nav-html [model: record, current_slug?: string] {
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

            [
                $"<li data-category-item data-search=\"(html-escape $category_search)\">"
                $"  <a class=\"nav-link($active_class)\" href=\"($category.slug).html\">(html-escape $category.title)</a>"
                $"  ($subnav)"
                '</li>'
            ] | str join "\n"
        }
        | str join "\n"
    )

    [
        '<p class="nav-group-title">Overview</p>'
        '<ul class="nav-list">'
        $"  <li><a class=\"nav-link($overview_active)\" href=\"index.html\">Introduction</a></li>"
        '</ul>'
        '<p class="nav-group-title">Categories</p>'
        '<ul class="nav-list">'
        $category_links
        '</ul>'
    ] | str join "\n"
}

export def render-index-page [model: record] {
    let overview_items = if (($model.categories | length) == 0) {
        '<div class="empty-state">No exported commands were found.</div>'
    } else {
        $model.categories
        | each {|category|
            let desc = if (($category.description | default '' | str trim) == '') {
                '<p class="overview-desc">No module description available.</p>'
            } else {
                $"<p class=\"overview-desc\">(html-escape $category.description)</p>"
            }
            [
                '<article class="overview-item">'
                $"  <h2>(html-escape $category.title)</h2>"
                $"  <p class=\"overview-meta\">($category.commands | length) commands</p>"
                $"  ($desc)"
                $"  <a class=\"overview-link\" href=\"($category.slug).html\">Open category</a>"
                '</article>'
            ] | str join "\n"
        }
        | str join "\n"
    }

    let lead = if (($model.summary | str trim) == '') {
        'Generated from Nushell source files and command help.'
    } else {
        $model.summary
    }

    let strip = [
        $"<span class=\"summary-pill\">($model.total_commands) total commands</span>"
        $"<span class=\"summary-pill\">($model.categories | length) categories</span>"
        $"<span class=\"summary-pill\">Source mode: (if $model.source_mode { 'multi-file' } else { 'single-file' })</span>"
    ] | str join "\n"

    let body = [
        $"<div class=\"summary-strip\">($strip)</div>"
        '<section class="overview-list">'
        $overview_items
        '</section>'
    ] | str join "\n"

    render-site-shell $model.name $model.summary_short $model.name $lead (render-nav-html $model) (render-search-index-json $model) $body
}

export def render-category-page [model: record, category: record] {
    let lead = if (($category.summary | str trim) == '') {
        $'Commands exported from ($category.file | path basename).'
    } else {
        $category.summary
    }
    let strip = [
        $"<span class=\"summary-pill\">File: <code>(html-escape ($category.file | path basename))</code></span>"
        $"<span class=\"summary-pill\">($category.commands | length) commands</span>"
    ] | str join "\n"

    let sections = if (($category.commands | length) == 0) {
        '<div class="empty-state">No exported commands were found in this file.</div>'
    } else {
        $category.commands
        | each {|command| render-command-html $command }
        | str join "\n"
    }

    let body = [
        $"<div class=\"summary-strip\">($strip)</div>"
        $"<section class=\"command-stack\">\n($sections)\n</section>"
    ] | str join "\n"

    render-site-shell $model.name $model.summary_short $category.title $lead (render-nav-html $model $category.slug) (render-search-index-json $model) $body
}
