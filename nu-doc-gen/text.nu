# Shared string and text rendering helpers.

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

export def first-paragraph [text: string] {
    split-paragraphs $text | first | default ''
}

export def strip-comment-prefix [line: string] {
    $line
    | str trim
    | str replace --regex '^#\s?' ''
}
