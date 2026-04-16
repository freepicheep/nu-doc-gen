# nu-doc-gen.nu
# Generates markdown documentation for a Nushell module using scope + help commands.

def format-definition-list [lines: list<string>]: nothing -> string {
    $lines
    | where {|l| ($l | str trim) != "" }
    | each {|l|
        let trimmed = $l | str trim
        let parts = $trimmed | split row ': ' | collect
        if ($parts | length) >= 2 {
            let name = $parts | first
            let desc = $parts | skip 1 | str join ': '
            $"- `($name)`: ($desc)"
        } else {
            $"- `($trimmed)`"
        }
    }
    | str join "\n"
}

def parse-help-to-markdown [command_name: string]: string -> string {
    let raw = $in

    # Split into lines, strip ANSI just in case
    let lines = $raw | lines

    # Extract the description: leading lines before the first header
    let first_header_idx = $lines | enumerate | where {|l| $l.item | str ends-with ':' } | first | get index? | default ($lines | length)

    let description = $lines | take $first_header_idx | str join "\n" | str trim

    # Parse sections: collect lines grouped under each header
    let sections: list<record> = $lines
        | skip $first_header_idx
        | reduce --fold [] {|line acc|
            if ($line | str ends-with ':') and (($line | str trim) != "") and not ($line | str starts-with ' ') and not ($line | str starts-with '>') {
                # New section header
                $acc | append {header: ($line | str trim | str replace ':' '') lines: []}
            } else {
                # Append to last section
                if ($acc | length) == 0 {
                    $acc
                } else {
                    let last = $acc | last
                    let rest = $acc | drop 1
                    $rest | append {header: $last.header lines: ($last.lines | append $line)}
                }
            }
        }

    # Render each section
    let sections_md = $sections | each {|sec|
            let header = $sec.header
            let body_lines = $sec.lines

            # Skip Command Type section (not very useful in docs)
            if $header == "Command Type" {
                return ""
            }

            let body = match $header {
                "Usage" => {
                    $body_lines
                    | where {|l| ($l | str trim) != "" }
                    | each {|l|
                        let trimmed = $l | str trim | str replace '> ' ''
                        $"`($trimmed)`"
                    }
                    | str join "\n"
                }
                "Examples" => {
                    # Group: description line followed by > command line(s)
                    $body_lines | reduce --fold {pairs: [] pending_desc: ""} {|line acc|
                        let trimmed = $line | str trim
                        if $trimmed == "" {
                            $acc
                        } else if ($trimmed | str starts-with '>') {
                            let code = $trimmed | str replace '> ' '' | str trim
                            let desc = if $acc.pending_desc != "" { $"# ($acc.pending_desc)\n" } else { "" }
                            {
                                pairs: ($acc.pairs | append $"```nu\n($desc)($code)\n```")
                                pending_desc: ""
                            }
                        } else {
                            {pairs: $acc.pairs pending_desc: $trimmed}
                        }
                    } | get pairs | str join "\n\n"
                }
                "Input/output types" => {
                    # Render as a simple markdown table (strip box-drawing chars)
                    let table_lines = $body_lines
                        | where {|l| ($l | str trim | str starts-with '│') }
                        | each {|l|
                            $l
                            | str replace --all '│' '|'
                            | str replace --all '╭' ''
                            | str replace --all '╰' ''
                            | str replace --all '├' ''
                            | str replace --all '┼' ''
                            | str replace --all '─' ''
                            | str trim
                        }
                    let header_row = $table_lines | first
                    let sep = $header_row | split row '|' | each {|_| '---' } | str join ' | ' | $"| ($in) |"
                    let data_rows = $table_lines | skip 1
                    ([$header_row $sep] | append $data_rows) | str join "\n"
                }
                "Flags" => {
                    format-definition-list $body_lines
                }
                "Parameters" => {
                    format-definition-list $body_lines
                }
                _ => {
                    $body_lines | str join "\n" | str trim
                }
            }

            if ($body | str trim) == "" {
                ""
            } else {
                $"### ($header)\n\n($body)"
            }
        } | where {|s| $s != "" } | str join "\n\n"

    # Assemble full command doc
    let desc_block = if ($description | str trim) == "" { "" } else { $"\n\n($description)" }
    $"## `($command_name)`($desc_block)\n\n($sections_md)"
}

# Generate markdown documentation for the specified module
@example "Generate docs for nu-salesforce" { generate-module-docs nu-salesforce nu-salesforce.md }
export def generate-module-docs [
    module_name: string # the module to generate docs for
    output_file: string = "docs.md" # the output file
] {
    # Wipe output file
    "" | save --force $output_file

    # Write title
    $"# ($module_name) — Module Reference\n\n" | save --append $output_file

    # Get all commands in module
    let commands = scope modules
        | where name == $module_name
        | get commands
        | flatten
        | get name

    if ($commands | length) == 0 {
        error make {msg: $"No module named '($module_name)' found in scope."}
    }

    print $"Generating docs for ($commands | length) commands in ($module_name | ansi gradient --fgstart '0x40c9ff' --fgend '0xe81cff')..."

    $commands | each {|cmd|
        print $"  → ($cmd)"
        let md = help $cmd | ansi strip | parse-help-to-markdown $cmd
        $"($md)\n\n---\n\n" | save --append $output_file
    }

    print $"\nDone! Docs written to: (ansi purple_bold)($output_file)(ansi reset)"
}
