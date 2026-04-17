use text.nu [quote-nu-string slugify first-paragraph strip-comment-prefix]
use help-doc.nu [parse-help-doc]

export def extract-file-summary [file_path: string] {
    let lines = (open --raw $file_path | lines)
    let summary_lines = (
        $lines
        | reduce --fold {started: false done: false summary: []} {|line, acc|
            if $acc.done {
                $acc
            } else {
                let trimmed = ($line | str trim)
                if (($trimmed | str starts-with '#')) {
                    {
                        started: true
                        done: false
                        summary: ($acc.summary | append (strip-comment-prefix $line))
                    }
                } else if ($trimmed == '') {
                    if $acc.started {
                        {
                            started: true
                            done: false
                            summary: ($acc.summary | append '')
                        }
                    } else {
                        $acc
                    }
                } else {
                    {
                        started: $acc.started
                        done: true
                        summary: $acc.summary
                    }
                }
            }
        }
        | get summary
    )

    $summary_lines | str join "\n" | str trim
}

export def nu-bin [] {
    which nu | get -o 0.path | default '/opt/homebrew/bin/nu'
}

export def run-nu-script [script: string] {
    let nu_path = (nu-bin)
    let result = (^$nu_path -c $script | complete)
    if $result.exit_code != 0 {
        error make {
            msg: $'Nu command failed: ($result.stderr | str trim)'
        }
    }

    $result.stdout
}

export def resolve-module-dir [module_path: string] {
    let expanded = ($module_path | path expand)
    let kind = ($expanded | path type)

    if $kind == 'dir' {
        let direct_mod = ([$expanded 'mod.nu'] | path join)
        if ($direct_mod | path exists) {
            return $expanded
        }

        let matches = (
            glob $"($expanded)/**/mod.nu"
            | where {|path|
                not ($path | str contains '/.nu-env/')
            }
        )

        if (($matches | length) == 1) {
            return (($matches | first) | path dirname)
        }

        if (($matches | length) == 0) {
            error make {msg: $'Could not find a mod.nu under ($expanded)'}
        }

        error make {msg: $'Found multiple mod.nu files under ($expanded). Pass the module directory or mod.nu path explicitly.'}
    }

    if ($kind == 'file') and (($expanded | path basename) == 'mod.nu') {
        return ($expanded | path dirname)
    }

    error make {msg: $'Expected a module directory or mod.nu file, got ($expanded)'}
}

export def module-files [module_dir: string] {
    let nu_files = (
        glob $"($module_dir)/*.nu"
        | sort
    )

    if (($nu_files | length) <= 1) {
        $nu_files
    } else {
        $nu_files | where {|name| ($name | path basename) != 'mod.nu' }
    }
}

export def collect-file-commands [file_path: string] {
    let file_literal = (quote-nu-string ($file_path | path expand))
    let before_stdout = (run-nu-script 'scope commands | where type == custom | select name | get name | to nuon' | str trim)
    let after_stdout = (run-nu-script $'use ($file_literal) *; scope commands | where type == custom | select name decl_id | sort-by decl_id | get name | to nuon' | str trim)

    if $after_stdout == '' {
        []
    } else {
        let before_names = if $before_stdout == '' { [] } else { $before_stdout | from nuon }
        let after_names = ($after_stdout | from nuon)
        $after_names | where {|command_name| $command_name not-in $before_names }
    }
}

export def collect-command-doc [file_path: string, command_name: string] {
    let file_literal = (quote-nu-string ($file_path | path expand))
    let command_literal = (quote-nu-string $command_name)
    let help_output = (run-nu-script $'use ($file_literal) *; help ($command_literal) | ansi strip')
    $help_output | parse-help-doc $command_name
}

export def collect-file-description [file_path: string] {
    let expanded_file = ($file_path | path expand)
    let file_literal = (quote-nu-string $expanded_file)
    let modules_stdout = (run-nu-script $'use ($file_literal) *; scope modules | select file description | to nuon' | str trim)

    if $modules_stdout == '' {
        ''
    } else {
        $modules_stdout
        | from nuon
        | where file == $expanded_file
        | get -o description
        | first
        | default ''
    }
}

export def collect-module-doc-model [module_path: string] {
    let module_dir = (resolve-module-dir $module_path)
    let mod_file = ([$module_dir 'mod.nu'] | path join)
    let module_name = ($module_dir | path basename)
    let files = (module-files $module_dir)

    let categories = (
        $files
        | each {|file_path|
            let commands = (collect-file-commands $file_path)
            if (($commands | length) == 0) {
                null
            } else {
                let title = ($file_path | path parse | get stem)
                {
                    title: $title
                    slug: (slugify $title)
                    file: $file_path
                    description: (collect-file-description $file_path)
                    summary: (extract-file-summary $file_path)
                    commands: ($commands | each {|command_name| collect-command-doc $file_path $command_name })
                }
            }
        }
        | compact
    )

    {
        name: $module_name
        module_dir: $module_dir
        summary: (extract-file-summary $mod_file)
        summary_short: (first-paragraph (extract-file-summary $mod_file))
        categories: $categories
        total_commands: ($categories | get commands | flatten | length)
        source_mode: (($files | length) > 1)
    }
}
