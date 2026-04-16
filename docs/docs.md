# nu-doc-gen — Module Reference

## `generate-module-docs`

Generate markdown documentation for the specified module

### Usage

`generate-module-docs <module_name> (output_file)`

### Flags

- `-h, --help`: Display the help message for this command

### Parameters

- `module_name <string>`: the module to generate docs for
- `output_file <string>`: the output file (optional, default: 'docs.md')

### Input/output types

| # | input | output |
| --- | --- | --- | --- | --- |
| 0 | any   | any    |

### Examples

```nu
# Generate docs for nu-salesforce
generate-module-docs nu-salesforce nu-salesforce.md
```

---

