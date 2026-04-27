# Shared string, escaping, and paragraph-formatting helpers for documentation rendering.

export def quote-nu-string [value: string] {
    let escaped = (
        $value
        | str replace --all '\' '\\'
        | str replace --all '"' '\"'
    )
    $"\"($escaped)\""
}

export def slugify [value: string] {
    $value
    | str downcase
    | str replace --regex --all '[^a-z0-9]+' '-'
    | str trim --char '-'
}

export def html-escape [value: string] {
    $value
    | str replace --all '&' '&amp;'
    | str replace --all '<' '&lt;'
    | str replace --all '>' '&gt;'
    | str replace --all '"' '&quot;'
}

export def count-label [count: int singular: string plural: string] {
    if $count == 1 {
        $"($count) ($singular)"
    } else {
        $"($count) ($plural)"
    }
}

export def split-paragraphs [text: string] {
    let reduced = (
        $text
        | lines
        | reduce --fold {paragraphs: [] current: []} {|line, acc|
            if (($line | str trim) == '') {
                if (($acc.current | length) == 0) {
                    $acc
                } else {
                    {
                        paragraphs: ($acc.paragraphs | append ($acc.current | str join ' '))
                        current: []
                    }
                }
            } else {
                {
                    paragraphs: $acc.paragraphs
                    current: ($acc.current | append ($line | str trim))
                }
            }
        }
    )

    $reduced.paragraphs | append (if (($reduced.current | length) == 0) { [] } else { [($reduced.current | str join ' ')] })
}

export def render-paragraphs-html [text: string] {
    let paragraphs = (split-paragraphs $text)
    if (($paragraphs | length) == 0) {
        ''
    } else {
        $paragraphs
        | each {|paragraph| $"<p>(html-escape $paragraph)</p>" }
        | str join "\n"
    }
}

def close-doc-paragraph [] {
    let acc = $in

    if (($acc.paragraph_lines | length) == 0) {
        $acc
    } else {
        let paragraph = ($acc.paragraph_lines | str join ' ')
        {
            blocks: ($acc.blocks | append $"<p>(html-escape $paragraph)</p>")
            paragraph_lines: []
            list_type: $acc.list_type
            list_items: $acc.list_items
        }
    }
}

def close-doc-list [] {
    let acc = $in

    if ($acc.list_type == '') {
        $acc
    } else {
        let items = (
            $acc.list_items
            | each {|item| $"<li>(html-escape $item)</li>" }
            | str join ''
        )
        {
            blocks: ($acc.blocks | append $"<($acc.list_type)>($items)</($acc.list_type)>")
            paragraph_lines: $acc.paragraph_lines
            list_type: ''
            list_items: []
        }
    }
}

def close-doc-blocks [] {
    $in | close-doc-paragraph | close-doc-list
}

def append-doc-list-item [acc: record list_type: string item: string] {
    let without_paragraph = ($acc | close-doc-paragraph)
    let ready = if ($without_paragraph.list_type == $list_type) {
        $without_paragraph
    } else {
        $without_paragraph | close-doc-list | merge {list_type: $list_type}
    }

    $ready | merge {list_items: ($ready.list_items | append $item)}
}

def append-doc-paragraph-line [acc: record line: string] {
    let without_list = ($acc | close-doc-list)
    $without_list | merge {paragraph_lines: ($without_list.paragraph_lines | append $line)}
}

export def render-doc-text-html [text: string] {
    let state = (
        $text
        | lines
        | reduce --fold {blocks: [] paragraph_lines: [] list_type: '' list_items: []} {|line, acc|
            let trimmed = ($line | str trim)
            if ($trimmed == '') {
                $acc | close-doc-blocks
            } else if ($trimmed =~ '^\d+\.\s+') {
                append-doc-list-item $acc ol ($trimmed | str replace --regex '^\d+\.\s+' '')
            } else if ($trimmed =~ '^[*-]\s+') {
                append-doc-list-item $acc ul ($trimmed | str replace --regex '^[*-]\s+' '')
            } else {
                append-doc-paragraph-line $acc $trimmed
            }
        }
        | close-doc-blocks
    )

    $state.blocks | str join "\n"
}

export def first-paragraph [text: string] {
    split-paragraphs $text | first | default ''
}

export def strip-comment-prefix [line: string] {
    $line
    | str trim
    | str replace --regex '^#\s?' ''
}
