# Theme registry loading, Ghostty palette parsing, and generated CSS/JSON helpers for themed sites.

const nu_doc_gen_dir = ((path self) | path dirname)
const bundled_ghostty_dir = ([ $nu_doc_gen_dir 'vendor' 'themes' ] | path join)
const theme_registry_file = ([ $nu_doc_gen_dir 'themes.toml' ] | path join)

def clamp-unit [value: number] {
    if $value < 0 {
        0
    } else if $value > 1 {
        1
    } else {
        $value
    }
}

def load-theme-registry [] {
    open $theme_registry_file | get themes
}

def hex-channel [color: string start: int end: int] {
    $color
    | str trim
    | str replace --regex '^#' ''
    | str substring $start..$end
    | into int --radix 16
    | $in / 255
}

def hex-color-components [color: string] {
    {
        red: (hex-channel $color 0 1)
        green: (hex-channel $color 2 3)
        blue: (hex-channel $color 4 5)
    }
}

def parse-ghostty-line [line: string] {
    let parsed = (
        $line
        | parse --regex '^(?<key>[^=]+?)\s*=\s*(?<value>.+)$'
    )

    if (($parsed | length) == 0) {
        null
    } else {
        let row = ($parsed | first)

        {
            key: ($row.key | str trim)
            value: ($row.value | str trim)
        }
    }
}

def load-ghostty-theme [ghostty_name: string] {
    let theme_file = ([ $bundled_ghostty_dir $ghostty_name ] | path join)

    if not ($theme_file | path exists) {
        error make {
            msg: $'Missing bundled Ghostty theme ''($ghostty_name)'' at ($theme_file).'
        }
    }

    let rows = (
        open --raw $theme_file
        | lines
        | each { str trim }
        | where {|line| $line != '' and not ($line | str starts-with '#') }
        | each {|line| parse-ghostty-line $line }
        | where {|row| $row != null }
    )

    let palette = (
        $rows
        | where key == 'palette'
        | each {|row|
            let parts = ($row.value | split row '=' | each { str trim })

            {
                name: $'ansi_(($parts | first) | into int)'
                value: (hex-color-components ($parts | last))
            }
        }
        | reduce --fold {} {|row, acc|
            $acc | upsert $row.name $row.value
        }
    )

    let colors = (
        $rows
        | where key != 'palette'
        | reduce --fold {} {|row, acc|
            let color_name = ($row.key | str replace --all '-' '_')
            $acc | upsert $color_name (hex-color-components $row.value)
        }
    )

    $colors | merge { palette: $palette }
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

def required-color [theme: record name: string] {
    if not ($name in ($theme | columns)) {
        error make {
            msg: $'Ghostty theme is missing required color ''($name)''.'
        }
    }

    $theme | get $name
}

def required-palette-color [theme: record index: int] {
    let name = $'ansi_($index)'

    if not ($name in ($theme.palette | columns)) {
        error make {
            msg: $'Ghostty theme is missing required palette color ''($index)''.'
        }
    }

    $theme.palette | get $name
}

def theme-css-vars [mode: string ghostty_theme: record] {
    let background = (required-color $ghostty_theme background)
    let foreground = (required-color $ghostty_theme foreground)
    let dim = (required-palette-color $ghostty_theme 8)
    let accent = (required-palette-color $ghostty_theme 4)
    let accent_strong = (required-palette-color $ghostty_theme 5)

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
    let ghostty_theme = (load-ghostty-theme $theme_entry.ghostty)

    $theme_entry
    | merge {
        css: (theme-css-vars $theme_entry.mode $ghostty_theme)
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
