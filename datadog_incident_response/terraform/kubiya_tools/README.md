# Kubiya Tools Directory

This directory contains organized Kubiya tool definitions and their associated scripts.

## Structure

```
kubiya_tools/
├── README.md (this file)
└── <tool_name>/
    ├── tool_definition.json    # Tool specification
    ├── <script_files>         # Python/shell scripts
    └── README.md              # Tool documentation
```

## Tool Organization

Each tool gets its own subdirectory containing:

### `tool_definition.json`
- Tool metadata (name, description, type, image)
- Argument specifications (name, type, required, description)
- Base configuration (content, files)

### Script Files
- Python scripts (`.py`)
- Shell scripts (`.sh`) 
- Any other tool dependencies

### `README.md`
- Tool-specific documentation
- Usage examples
- Argument descriptions
- Error handling notes

## Benefits

1. **🗂️ Organized Structure**: Each tool is self-contained
2. **📝 Easy Maintenance**: Separate files for definitions and scripts
3. **🔄 Reusable**: Tool definitions can be shared across workflows
4. **📚 Documented**: Each tool has its own documentation
5. **🧪 Testable**: Scripts can be tested independently
6. **🔍 Version Control**: Clear diffs for tool changes

## Usage in Terraform

Tools are loaded using:
```hcl
locals {
  tool_def = jsondecode(file("${path.module}/kubiya_tools/tool_name/tool_definition.json"))
  tool_script = file("${path.module}/kubiya_tools/tool_name/script.py")
}
```

Then used in workflow steps:
```hcl
executor = {
  type = "tool"
  config = {
    tool_def = merge(local.tool_def, {
      with_files = [
        {
          destination = "/tmp/script.py"
          content = local.tool_script
        }
      ]
    })
    args = { ... }
  }
}
```

## Current Tools

- **markdown_uploader**: Posts investigation results to Slack with formatting