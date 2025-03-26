# Kubernetes JIT Access Control

This module provides just-in-time access control for Kubernetes tools in Kubiya, using OPA policies to enforce tool usage constraints.

## Dynamic Tool Validation

The module supports dynamic validation of tool parameters through Terraform variables. This allows you to control which tools require specific parameter patterns without modifying the policy code.

### Example Usage

```hcl
module "kubernetes_jit" {
  source = "path/to/module"
  
  restricted_tools = [
    "helm",
    "docker"
  ]
  
  tool_validation_rules = {
    "kubectl" = {
      description = "Rules for kubectl commands"
      parameters = [
        {
          name             = "command"
          required_pattern = "-n kubiya"
          match_type       = "contains"
          description      = "Kubectl commands must specify the kubiya namespace"
        }
      ]
    },
    "helm" = {
      description = "Rules for helm commands"
      parameters = [
        {
          name             = "args"
          required_pattern = "--namespace kubiya"
          match_type       = "contains"
          description      = "Helm commands must specify the kubiya namespace"
        }
      ],
    },
    "aws" = {
      description = "Rules for AWS CLI commands"
      parameters = [
        {
          name             = "region"
          required_pattern = "us-west-2"
          match_type       = "exact"
          description      = "AWS commands must use the us-west-2 region"
        }
      ]
    }
  }
}
```

## Input Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| restricted_tools | Tools to add to the restricted category | list(string) | [] |
| tool_validation_rules | Validation rules for tool parameters | map(object) | See below |

### Default Tool Validation Rules

By default, the module comes with validation for `kubectl` commands to ensure they include the `-n kubiya` namespace flag.

## Match Types

The policy supports two types of parameter matching:

1. **contains** - Checks if the parameter value contains the required pattern
2. **exact** - Requires the parameter value to exactly match the required pattern

## How It Works

1. The OPA policy loads the tool validation rules from Terraform
2. When a tool is invoked, it checks if there are validation rules for that tool
3. If rules exist, it verifies that the tool parameters match the required patterns using the specified match type
4. Tools without validation rules are allowed without parameter checks
5. Admins can still run admin and revoke tools regardless of validation rules

## Adding New Tool Validations

To add validation for a new tool:

1. Add the tool and its parameter validation rules to the `tool_validation_rules` variable
2. Each validation rule needs:
   - The parameter name to check
   - The required pattern that must be present in the parameter value
   - The match type ("contains" or "exact")
   - A description of the rule for documentation

The policy will automatically enforce the new validation rules without any code changes. 