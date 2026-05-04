# Runtime helpers for building a documentation model from an already-loaded Nushell plugin.

use help-doc.nu [parse-help-doc]
use module-source.nu [nu-doc-gen-version]
use text.nu [first-paragraph]

export def collect-plugin-command-names [
    plugin_name: string
    exclude_plugin_command: bool = false
] {
    let commands = (
        plugin list
        | where name == $plugin_name
        | get commands.name
        | first
        | default []
    )

    if (($commands | length) == 0) {
        error make {msg: $'No loaded plugin named ''($plugin_name)'' was found.'}
    }

    let filtered = if $exclude_plugin_command {
        $commands | where {|command_name| $command_name != $plugin_name }
    } else {
        $commands
    }

    if (($filtered | length) == 0) {
        error make {msg: $'No commands remain for plugin ''($plugin_name)'' after filtering.'}
    }

    $filtered | sort
}

export def collect-plugin-doc [command_name: string] {
    help $command_name
    | ansi strip
    | parse-help-doc $command_name
}

export def collect-plugin-doc-model [
    plugin_name: string
    exclude_plugin_command: bool = false
] {
    let plugin_record = (
        plugin list
        | where name == $plugin_name
        | first
        | default null
    )

    if $plugin_record == null {
        error make {msg: $'No loaded plugin named ''($plugin_name)'' was found.'}
    }

    let commands = (collect-plugin-command-names $plugin_name $exclude_plugin_command)
    let summary = ($plugin_record.description? | default '')
    let command_docs = ($commands | each {|command_name| collect-plugin-doc $command_name })

    {
        kind: 'plugin'
        name: $plugin_name
        summary: $summary
        summary_short: (first-paragraph $summary)
        categories: []
        commands: $command_docs
        total_commands: ($commands | length)
        package_version: ($plugin_record.version? | default '')
        nu_doc_gen_version: (nu-doc-gen-version)
        source_mode: false
        source_label: 'plugin runtime'
        site_label: 'Nu Plugin Docs'
        exclude_plugin_command: $exclude_plugin_command
    }
}
