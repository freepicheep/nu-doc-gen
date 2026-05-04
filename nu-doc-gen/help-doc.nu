# Parsers and renderers for turning Nushell help output into structured markdown and HTML documentation.

use text.nu *

const help_section_headers = [
    'Usage'
    'Subcommands'
    'Flags'
    'Signatures'
    'Parameters'
    'Input/output types'
    'Examples'
    'Command Type'
]

def is-help-section-header [line: string] {
    let trimmed = ($line | str trim)
    let header = ($trimmed | str replace ':' '')
    let has_colon = ($trimmed | str ends-with ':')
    let is_left_aligned = not ($line | str starts-with ' ')
    let is_not_example = not ($line | str starts-with '>')

    $has_colon and ($trimmed != '') and $is_left_aligned and $is_not_example and ($header in $help_section_headers)
}

export def parse-definition-items [lines: list<string>] {
    $lines
    | where {|line| ($line | str trim) != '' }
    | each {|line|
        let trimmed = ($line | str trim)
        let parts = ($trimmed | split row ': ')
        if (($parts | length) >= 2) {
            {
                name: ($parts | first)
                description: ($parts | skip 1 | str join ': ')
            }
        } else {
            {
                name: $trimmed
                description: ''
            }
        }
    }
}

export def render-definition-list-markdown [items: list<record<name: string, description: string>>] {
    $items
    | each {|item|
        if ($item.description == '') {
            $"- `($item.name)`"
        } else {
            $"- `($item.name)`: ($item.description)"
        }
    }
    | str join "\n"
}

export def render-definition-list-html [items: list<record<name: string, description: string>>] {
    let rendered = (
        $items
        | each {|item|
            let desc = if ($item.description == '') { '' } else { $"<dd>(html-escape $item.description)</dd>" }
            $"<div class=\"def-item\"><dt><code>(html-escape $item.name)</code></dt>($desc)</div>"
        }
        | str join "\n"
    )

    $"<dl class=\"def-list\">($rendered)
</dl>"
}

export def parse-examples [lines: list<string>] {
    $lines
    | reduce --fold {pairs: [] pending_desc: ''} {|line acc|
        let trimmed = ($line | str trim)
        if $trimmed == '' {
            $acc
        } else if ($trimmed | str starts-with '>') {
            {
                pairs: (
                    $acc.pairs | append {
                        description: $acc.pending_desc
                        code: ($trimmed | str replace --regex '^>\s*' '')
                    }
                )
                pending_desc: ''
            }
        } else {
            {
                pairs: $acc.pairs
                pending_desc: $trimmed
            }
        }
    }
    | get pairs
}

export def render-examples-markdown [examples: list<record<description: string, code: string>>] {
    $examples
    | each {|example|
        let desc = if ($example.description == '') { '' } else { $"# ($example.description)\n" }
        $"```nu\n($desc)($example.code)\n```"
    }
    | str join "\n\n"
}

export def render-examples-html [examples: list<record<description: string, code: string>>] {
    $examples
    | each {|example|
        let label = if ($example.description == '') { '' } else { $"<p class=\"example-label\">(html-escape $example.description)</p>" }
        $"<div class=\"example-block\">($label)<pre data-shiki-lang=\"nushell\"><code class=\"language-nushell\" data-shiki-source=\"nushell\">(html-escape $example.code)</code></pre></div>"
    }
    | str join "\n"
}

export def parse-io-table [lines: list<string>] {
    let cells = (
        $lines
        | where {|line| ($line | str trim | str starts-with '│') }
        | each {|line|
            $line
            | str trim
            | str replace --all '│' '|'
            | split row '|'
            | each {|cell| $cell | str trim }
            | where {|cell| $cell != '' }
        }
    )

    if (($cells | length) == 0) {
        {header: [] rows: []}
    } else {
        {
            header: ($cells | first)
            rows: ($cells | skip 1)
        }
    }
}

export def render-io-table-markdown [table: record<header: list<string>, rows: list<list<string>>>] {
    if (($table.header | length) == 0) {
        ''
    } else {
        let header = ($table.header | str join ' | ')
        let separator = ($table.header | each {|_| '---' } | str join ' | ')
        let rows = (
            $table.rows
            | each {|row| $row | str join ' | ' }
        )

        ([$"| ($header) |" $"| ($separator) |"] | append ($rows | each {|row| $"| ($row) |" }))
        | str join "\n"
    }
}

export def render-io-table-html [table: record<header: list<string>, rows: list<list<string>>>] {
    if (($table.header | length) == 0) {
        ''
    } else {
        let head = (
            $table.header
            | each {|cell| $"<th>(html-escape $cell)</th>" }
            | str join ''
        )
        let rows = (
            $table.rows
            | each {|row|
                let cells = ($row | each {|cell| $"<td>(html-escape $cell)</td>" } | str join '')
                $"<tr>($cells)</tr>"
            }
            | str join "\n"
        )

        $"<table class=\"io-table\"><thead><tr>($head)</tr></thead><tbody>($rows)
</tbody></table>"
    }
}

export def parse-help-doc [command_name: string] {
    let raw = $in
    let lines = ($raw | lines)
    let first_header_idx = (
        $lines
        | enumerate
        | where {|row| is-help-section-header $row.item }
        | first
        | get index?
        | default ($lines | length)
    )

    let description = ($lines | take $first_header_idx | str join "\n" | str trim)
    let sections = (
        $lines
        | skip $first_header_idx
        | reduce --fold [] {|line acc|
            let trimmed = ($line | str trim)
            if (is-help-section-header $line) {
                $acc | append {header: ($trimmed | str replace ':' '') lines: []}
            } else if (($acc | length) == 0) {
                $acc
            } else {
                let last = ($acc | last)
                let rest = ($acc | drop nth (($acc | length) - 1))
                $rest | append {header: $last.header lines: ($last.lines | append $line)}
            }
        }
        | each {|section|
            let header = $section.header
            let body_lines = $section.lines
            let kind = (
                match $header {
                    'Usage' => { 'usage' }
                    'Examples' => { 'examples' }
                    'Input/output types' => { 'io-table' }
                    'Flags' => { 'definitions' }
                    'Parameters' => { 'definitions' }
                    _ => { 'text' }
                }
            )
            let value = (
                match $kind {
                    'usage' => {
                        $body_lines
                        | where {|line| ($line | str trim) != '' }
                        | each {|line| $line | str trim | str replace --regex '^>\s*' '' }
                    }
                    'examples' => { parse-examples $body_lines }
                    'io-table' => { parse-io-table $body_lines }
                    'definitions' => { parse-definition-items $body_lines }
                    _ => { $body_lines | str join "\n" | str trim }
                }
            )
            {
                header: $header
                kind: $kind
                value: $value
            }
        }
        | where {|section| $section.header != 'Command Type' }
    )

    {
        name: $command_name
        slug: (slugify $command_name)
        description: $description
        sections: $sections
    }
}

export def render-section-markdown [section: record] {
    let body = (
        match $section.kind {
            'usage' => {
                $section.value
                | each {|line| $"`($line)`" }
                | str join "\n"
            }
            'examples' => { render-examples-markdown $section.value }
            'io-table' => { render-io-table-markdown $section.value }
            'definitions' => { render-definition-list-markdown $section.value }
            _ => { render-doc-text-markdown $section.value }
        }
    )

    if (($body | str trim) == '') {
        ''
    } else {
        $"### ($section.header)\n\n($body)"
    }
}

export def render-command-markdown [doc: record] {
    let desc_block = if (($doc.description | str trim) == '') {
        ''
    } else {
        $"\n\n(render-doc-text-markdown $doc.description)"
    }
    let sections_md = (
        $doc.sections
        | each {|section| render-section-markdown $section }
        | where {|section| $section != '' }
        | str join "\n\n"
    )

    $"## `($doc.name)`($desc_block)\n\n($sections_md)"
}

export def render-section-html [section: record] {
    let body = (
        match $section.kind {
            'usage' => {
                $section.value
                | each {|line| $"<pre data-shiki-lang=\"nushell\"><code class=\"language-nushell\" data-shiki-source=\"nushell\">(html-escape $line)</code></pre>" }
                | str join "\n"
            }
            'examples' => { render-examples-html $section.value }
            'io-table' => { render-io-table-html $section.value }
            'definitions' => { render-definition-list-html $section.value }
            _ => { $"<div class=\"section-text\">(render-doc-text-html $section.value)</div>" }
        }
    )

    if (($body | str trim) == '') {
        ''
    } else {
        $"<section class=\"doc-section\"><h3>(html-escape $section.header)</h3>($body)
</section>"
    }
}

export def render-command-html [doc: record] {
    let description = if (($doc.description | str trim) == '') {
        ''
    } else {
        $"<div class=\"command-description\">(render-doc-text-html $doc.description)</div>"
    }
    let export_badge = if ($doc.is_exported? | default true) {
        ''
    } else {
        '<span class="command-badge command-badge-internal">Internal</span>'
    }

    let sections = (
        $doc.sections
        | each {|section| render-section-html $section }
        | where {|section| $section != '' }
        | str join "\n"
    )

    $"<article class=\"command-section\" id=\"($doc.slug)\"><div class=\"command-heading\"><h2><code>(html-escape $doc.name)</code></h2>($export_badge)</div>($description)($sections)
</article>"
}
