# Runtime helpers for building a documentation model from an already-loaded Nushell plugin.

use help-doc.nu [parse-help-doc]
use module-source.nu [nu-doc-gen-version]
use text.nu [first-paragraph]

export def collect-plugin-command-names [plugin_name: string] {
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

    $commands | sort
}

export def collect-plugin-doc [command_name: string] {
    help $command_name
    | ansi strip
    | parse-help-doc $command_name
}

export def collect-plugin-doc-model [plugin_name: string] {
    let plugin_record = (
        plugin list
        | where name == $plugin_name
        | first
        | default null
    )

    if $plugin_record == null {
        error make {msg: $'No loaded plugin named ''($plugin_name)'' was found.'}
    }

    let commands = (collect-plugin-command-names $plugin_name)
    let summary = ($plugin_record.description? | default '')
    let category = {
        title: 'Commands'
        slug: 'commands'
        file: $plugin_name
        description: $summary
        summary: (if (($summary | str trim) == '') {
            $'Commands exposed by the loaded ($plugin_name) plugin.'
        } else {
            $summary
        })
        commands: ($commands | each {|command_name| collect-plugin-doc $command_name })
    }

    {
        kind: 'plugin'
        name: $plugin_name
        summary: $summary
        summary_short: (first-paragraph $summary)
        categories: [$category]
        total_commands: ($commands | length)
        package_version: ($plugin_record.version? | default '')
        nu_doc_gen_version: (nu-doc-gen-version)
        source_mode: false
        source_label: 'plugin runtime'
        site_label: 'Nu Plugin Docs'
    }
}
