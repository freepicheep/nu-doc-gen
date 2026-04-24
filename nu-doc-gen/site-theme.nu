# Theme registry loading, iTerm2 palette parsing, and generated CSS/JSON helpers for themed sites.

const nu_doc_gen_dir = ((path self) | path dirname)
const bundled_iterm_dir = ([ $nu_doc_gen_dir 'vendor' 'iterm2' ] | path join)
const theme_registry_file = ([ $nu_doc_gen_dir 'themes.nuon' ] | path join)

def clamp-unit [value: number] {
    if $value < 0 {
        0
    } else if $value > 1 {
        1
    } else {
        $value
    }
}

def plist-node-to-value [node: record] {
    match $node.tag {
        'dict' => {
            $node.content
            | chunks 2
            | reduce --fold {} {|pair, acc|
                let key = ($pair | get 0.content.0.content)
                let value = (plist-node-to-value ($pair | get 1))
                $acc | upsert $key $value
            }
        }
        'string' => { $node.content.0.content }
        'real' => { $node.content.0.content | into float }
        'integer' => { $node.content.0.content | into int }
        'true' => { true }
        'false' => { false }
        _ => { null }
    }
}

def load-theme-registry [] {
    open $theme_registry_file
}

def load-iterm-theme [iterm_name: string] {
    let theme_file = ([ $bundled_iterm_dir $'($iterm_name).itermcolors' ] | path join)

    if not ($theme_file | path exists) {
        error make {
            msg: $'Missing bundled iTerm theme ''($iterm_name)'' at ($theme_file).'
        }
    }

    let xml = (open --raw $theme_file | from xml --allow-dtd)
    plist-node-to-value ($xml.content | first)
}

def lookup-theme-entry [registry: list<record> theme_name: string mode: string] {
    let matches = (
        $registry
        | where shiki == $theme_name and mode == $mode
    )

    if (($matches | length) == 0) {
        let supported = (
            $registry
            | where mode == $mode
            | get shiki
            | sort
            | str join ', '
        )

        error make {
            msg: $'Unsupported ($mode) theme ''($theme_name)''.'
            help: $'Supported ($mode) themes: ($supported)'
        }
    }

    $matches | first
}

def color-components [plist_color: record] {
    {
        red: ($plist_color.'Red Component' | default 0.0)
        green: ($plist_color.'Green Component' | default 0.0)
        blue: ($plist_color.'Blue Component' | default 0.0)
    }
}

def mix-color [base: record other: record weight: number] {
    let blend = (clamp-unit $weight)

    {
        red: (($base.red * (1 - $blend)) + ($other.red * $blend))
        green: (($base.green * (1 - $blend)) + ($other.green * $blend))
        blue: (($base.blue * (1 - $blend)) + ($other.blue * $blend))
    }
}

def lighten [color: record weight: number] {
    mix-color $color {red: 1.0 green: 1.0 blue: 1.0} $weight
}

def darken [color: record weight: number] {
    mix-color $color {red: 0.0 green: 0.0 blue: 0.0} $weight
}

def channel-byte [value: number] {
    (((clamp-unit $value) * 255) | math round | into int)
}

def channel-hex [value: number] {
    channel-byte $value
    | into binary --compact
    | encode hex
    | str downcase
}

def color-hex [color: record] {
    $'#(channel-hex $color.red)(channel-hex $color.green)(channel-hex $color.blue)'
}

def color-rgba [color: record alpha: number] {
    let red = (channel-byte $color.red)
    let green = (channel-byte $color.green)
    let blue = (channel-byte $color.blue)

    ['rgba(' $red ', ' $green ', ' $blue ', ' $alpha ')'] | str join
}

def theme-css-vars [mode: string iterm_theme: record] {
    let background = (color-components $iterm_theme.'Background Color')
    let foreground = (color-components $iterm_theme.'Foreground Color')
    let dim = (color-components $iterm_theme.'Ansi 8 Color')
    let accent = (color-components $iterm_theme.'Ansi 4 Color')
    let accent_strong = (color-components $iterm_theme.'Ansi 5 Color')

    let bg_start = if $mode == 'light' {
        lighten $background 0.03
    } else {
        lighten $background 0.04
    }
    let bg_end = if $mode == 'light' {
        darken $background 0.03
    } else {
        darken $background 0.02
    }
    let surface = if $mode == 'light' {
        lighten $background 0.06
    } else {
        lighten $background 0.03
    }
    let surface_strong = if $mode == 'light' {
        mix-color $background $dim 0.24
    } else {
        mix-color $background $dim 0.28
    }
    let surface_muted = if $mode == 'light' {
        mix-color $background $dim 0.16
    } else {
        mix-color $background $dim 0.18
    }
    let border = if $mode == 'light' {
        mix-color $background $dim 0.28
    } else {
        mix-color $background $dim 0.35
    }
    let accent_soft = if $mode == 'light' {
        mix-color $background $accent 0.16
    } else {
        mix-color $background $accent 0.18
    }
    let shadow = if $mode == 'light' {
        $'0 16px 40px (color-rgba $foreground 0.08)'
    } else {
        $'0 18px 42px (color-rgba {red: 0.0 green: 0.0 blue: 0.0} 0.42)'
    }
    let surface_alpha = if $mode == 'light' {
        color-rgba $surface 0.82
    } else {
        color-rgba $surface 0.88
    }
    let sidebar_bg = (color-rgba $surface 0.94)
    let table_stripe = if $mode == 'light' {
        color-rgba $accent 0.04
    } else {
        color-rgba $accent 0.07
    }

    {
        bg: (color-hex $background)
        bg_start: (color-hex $bg_start)
        bg_end: (color-hex $bg_end)
        surface: (color-hex $surface)
        surface_alpha: $surface_alpha
        sidebar_bg: $sidebar_bg
        surface_strong: (color-hex $surface_strong)
        surface_muted: (color-hex $surface_muted)
        text: (color-hex $foreground)
        muted: (color-hex (mix-color $foreground $background 0.42))
        border: (color-hex $border)
        accent: (color-hex $accent)
        accent_strong: (color-hex $accent_strong)
        accent_soft: (color-hex $accent_soft)
        code_bg: (color-hex $surface_strong)
        code_text: (color-hex $foreground)
        shadow: $shadow
        table_stripe: $table_stripe
    }
}

def resolve-theme-details [theme_entry: record] {
    let iterm_theme = (load-iterm-theme $theme_entry.iterm)

    $theme_entry
    | merge {
        css: (theme-css-vars $theme_entry.mode $iterm_theme)
    }
}

def render-css-vars [vars: record] {
    $vars
    | transpose name value
    | each {|row|
        let css_name = ($row.name | str replace --all '_' '-')
        $'    --($css_name): ($row.value);'
    }
    | str join "\n"
}

export def resolve-site-theme-pair [
    light_theme: string
    dark_theme: string
] {
    let registry = (load-theme-registry)
    let light_entry = (lookup-theme-entry $registry $light_theme 'light')
    let dark_entry = (lookup-theme-entry $registry $dark_theme 'dark')

    {
        light: (resolve-theme-details $light_entry)
        dark: (resolve-theme-details $dark_entry)
    }
}

export def site-theme-css [theme_pair: record] {
    let light_vars = (render-css-vars $theme_pair.light.css)
    let dark_vars = (render-css-vars $theme_pair.dark.css)

    [
        ':root {'
        '    color-scheme: light dark;'
        $light_vars
        '}'
        ''
        '[data-theme="light"] {'
        '    color-scheme: light;'
        '}'
        ''
        '[data-theme="dark"] {'
        '    color-scheme: dark;'
        $dark_vars
        '}'
        ''
        '@media (prefers-color-scheme: dark) {'
        '    :root:not([data-theme="light"]) {'
        '        color-scheme: dark;'
        $dark_vars
        '    }'
        '}'
    ] | str join "\n"
}

export def site-theme-config-json [theme_pair: record] {
    {
        shiki: {
            light: $theme_pair.light.shiki
            dark: $theme_pair.dark.shiki
        }
    }
    | to json --raw
    | str replace --all '</' '<\/'
}
