# Builders and renderers that turn `scope commands` records into structured doc records and markdown/HTML output.

use text.nu *

def signature-usage [command_name: string, signature: table]: nothing -> string {
    let positionals = (
        $signature
        | where parameter_type == 'positional'
        | each {|p|
            let optional = if $p.is_optional { '?' } else { '' }
            $"<($p.parameter_name)($optional)>"
        }
    )
    let rest = (
        $signature
        | where parameter_type == 'rest'
        | each {|p| $"...<($p.parameter_name)>" }
    )
    let named = (
        $signature
        | where parameter_type == 'named'
        | each {|p|
            let shape = ($p.syntax_shape | default '' | str trim)
            let value = if $shape == '' { '' } else { $" <($shape)>" }
            $"--($p.parameter_name)($value)"
        }
    )
    let switches = (
        $signature
        | where parameter_type == 'switch'
        | each {|p| $"[--($p.parameter_name)]" }
    )

    [$command_name]
    | append $positionals
    | append $rest
    | append $named
    | append $switches
    | str join ' '
}

def format-default-value [value: any]: nothing -> string {
    if ($value | describe) == 'string' {
        $"'($value)'"
    } else {
        $value | to nuon
    }
}

def positional-description [param: record]: nothing -> string {
    let base = ($param.description | default '')
    let is_optional = ($param.parameter_type == 'positional') and $param.is_optional
    let has_default = $param.parameter_default != null
    let suffix = if $is_optional and $has_default {
        $"\(optional, default: (format-default-value $param.parameter_default)\)"
    } else if $is_optional {
        '(optional)'
    } else if $has_default {
        $"\(default: (format-default-value $param.parameter_default)\)"
    } else {
        ''
    }

    if $suffix == '' {
        $base
    } else if ($base | str trim) == '' {
        $suffix
    } else {
        $"($base) ($suffix)"
    }
}

def flag-description [param: record]: nothing -> string {
    let base = ($param.description | default '')
    if $param.parameter_default == null {
        $base
    } else {
        let suffix = $"\(default: (format-default-value $param.parameter_default)\)"
        if ($base | str trim) == '' {
            $suffix
        } else {
            $"($base) ($suffix)"
        }
    }
}

def shape-suffix [param: record]: nothing -> string {
    let shape = ($param.syntax_shape | default '' | str trim)
    if $shape == '' { '' } else { $" <($shape)>" }
}

def signature-params [signature: table]: nothing -> list {
    let positionals = ($signature | where parameter_type == 'positional')
    let rest = ($signature | where parameter_type == 'rest')

    $positionals
    | append $rest
    | each {|p|
        let prefix = if $p.parameter_type == 'rest' { '...' } else { '' }
        {
            name: $"($prefix)($p.parameter_name)(shape-suffix $p)"
            description: (positional-description $p)
        }
    }
}

def signature-flags [signature: table]: nothing -> list {
    let named = ($signature | where parameter_type == 'named')
    let switches = ($signature | where parameter_type == 'switch')

    $named
    | append $switches
    | each {|p|
        let short = if $p.short_flag == null { '' } else { $" \(-($p.short_flag)\)" }
        let value = if $p.parameter_type == 'switch' { '' } else { (shape-suffix $p) }
        {
            name: $"--($p.parameter_name)($short)($value)"
            description: (flag-description $p)
        }
    }
}

def signatures-io-table [signatures: record]: nothing -> record {
    let rows = (
        $signatures
        | columns
        | each {|key|
            let sig = ($signatures | get $key)
            let input = ($sig | where parameter_type == 'input' | get -o syntax_shape | first | default '')
            let output = ($sig | where parameter_type == 'output' | get -o syntax_shape | first | default '')
            [$input $output]
        }
        | where {|row| (($row | get 0) != '') or (($row | get 1) != '') }
    )

    if (($rows | length) == 0) {
        {header: [] rows: []}
    } else {
        {header: [input output] rows: $rows}
    }
}

def scope-examples-to-doc [examples: list]: nothing -> list {
    $examples
    | each {|ex|
        let raw_result = ($ex.result? | default null)
        let result_text = if $raw_result == null { '' } else { $raw_result | table | into string | str trim --right }
        {
            description: ($ex.description? | default '')
            code: ($ex.example? | default '')
            result: $result_text
        }
    }
    | where {|e| ($e.code | str trim) != '' }
}

def section-is-empty [section: record]: nothing -> bool {
    match $section.kind {
        'usage' => { ($section.value | length) == 0 }
        'definitions' => { ($section.value | length) == 0 }
        'examples' => { ($section.value | length) == 0 }
        'io-table' => { ($section.value.rows | length) == 0 }
        _ => { ($section.value | str trim) == '' }
    }
}

# Build a structured doc record from a `scope commands` row.
export def build-command-doc []: record -> record {
    let cmd = $in
    let signatures = ($cmd.signatures? | default {})
    let signature_keys = ($signatures | columns)
    let primary_signature = if (($signature_keys | length) == 0) {
        []
    } else {
        $signatures | get ($signature_keys | first)
    }

    let summary = ($cmd.description? | default '' | str trim)
    let extra = ($cmd.extra_description? | default '' | str trim)
    let description = if $extra == '' {
        $summary
    } else if $summary == '' {
        $extra
    } else {
        $"($summary)\n\n($extra)"
    }

    let usage_lines = if (($signature_keys | length) == 0) {
        [$cmd.name]
    } else {
        [(signature-usage $cmd.name $primary_signature)]
    }

    let sections = (
        [
            {header: 'Usage' kind: 'usage' value: $usage_lines}
            {header: 'Parameters' kind: 'definitions' value: (signature-params $primary_signature)}
            {header: 'Flags' kind: 'definitions' value: (signature-flags $primary_signature)}
            {header: 'Input/output types' kind: 'io-table' value: (signatures-io-table $signatures)}
            {header: 'Examples' kind: 'examples' value: (scope-examples-to-doc ($cmd.examples? | default []))}
        ]
        | where {|section| not (section-is-empty $section) }
    )

    {
        name: $cmd.name
        slug: (slugify $cmd.name)
        description: $description
        sections: $sections
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

export def render-examples-markdown [examples: list<record<description: string, code: string, result: string>>] {
    $examples
    | each {|example|
        let desc = if ($example.description == '') { '' } else { $"# ($example.description)\n" }
        let code_block = $"```nu\n($desc)($example.code)\n```"
        let result_block = if (($example.result? | default '') == '') { '' } else { $"\n\n```\n($example.result)\n```" }
        $"($code_block)($result_block)"
    }
    | str join "\n\n"
}

export def render-examples-html [examples: list<record<description: string, code: string, result: string>>] {
    $examples
    | each {|example|
        let label = if ($example.description == '') { '' } else { $"<p class=\"example-label\">(html-escape $example.description)</p>" }
        let result_block = if (($example.result? | default '') == '') {
            ''
        } else {
            $"<div class=\"example-result\"><span class=\"example-result-tag\">returns</span><pre class=\"example-result-body\"><code>(html-escape $example.result)</code></pre>
</div>"
        }
        $"<div class=\"example-block\">($label)<pre data-shiki-lang=\"nushell\"><code class=\"language-nushell\" data-shiki-source=\"nushell\">(html-escape $example.code)</code></pre>($result_block)</div>"
    }
    | str join "\n"
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
            _ => { $section.value }
        }
    )

    if (($body | str trim) == '') {
        ''
    } else {
        $"### ($section.header)\n\n($body)"
    }
}

export def render-command-markdown [doc: record] {
    let desc_block = if (($doc.description | str trim) == '') { '' } else { $"\n\n($doc.description)" }
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
