locals {
  # Define the base restricted tools
  # base_restricted_tools = ["kubectl"]
  base_restricted_tools = []

  # Convert the array to a Rego set format
  rego_restricted_tools = join(", ", [for tool in var.restricted_tools : "\"${tool}\""])

  # Format tool validation rules for Rego
  tool_validation_rules_rego = jsonencode(var.tool_validation_rules)

  # Define the policy template
  policy_template = <<-EOT
package kubiya.tool_manager

# Default deny all access
default allow = false

# Define tool categories with our restricted tools
tool_categories := {
    "admin": {
        "list_active_access_requests",
        "view_user_requests",
        "approve_tool_access_request",
        "describe_access_request"
    },
    "revoke": {
    },
    "restricted": {
        ${local.rego_restricted_tools}
    }
}

# Tool validation rules imported from Terraform
tool_validation_rules := ${local.tool_validation_rules_rego}

# Helper functions
is_admin(user) {
    user.groups[_].name == "Admin"
}

is_tool_in_category(tool_name, category) {
    tool_categories[category][tool_name]
}

# Check if parameter value matches the required pattern based on match_type
parameter_matches(value, pattern, match_type) {
    # For contains matching
    match_type == "contains"
    contains(value, pattern)
}

parameter_matches(value, pattern, match_type) {
    # For exact matching
    match_type == "exact"
    value == pattern
}

# Check if a tool's parameters match the required validation rules
tool_passes_validation(tool) {
    # If no validation rules for this tool, it passes by default
    not tool_validation_rules[tool.name]
}

tool_passes_validation(tool) {
    # Get rules for this specific tool
    rules := tool_validation_rules[tool.name]
    
    # Check each parameter rule
    parameter := rules.parameters[_]
    
    # Get parameter name, required value/pattern, and match type
    param_name := parameter.name
    required_pattern := parameter.required_pattern
    match_type := parameter.match_type
    
    # Verify parameter exists and matches the required pattern
    tool.parameters[param_name]
    parameter_matches(tool.parameters[param_name], required_pattern, match_type)
}

# Rules
# Allow administrators to run admin tools
allow {
    is_admin(input.user)
    is_tool_in_category(input.tool.name, "admin")
}

# Allow administrators to run revoke tools
allow {
    is_admin(input.user)
    is_tool_in_category(input.tool.name, "revoke")
}

# Deny tools that fail validation rules
deny {
    # Tool has validation rules
    tool_validation_rules[input.tool.name]
    
    # But fails validation
    not tool_passes_validation(input.tool)
}

# Allow everyone to run non-admin, non-restricted tools that pass validation
allow {
    # Check that the tool is not in any restricted category
    not is_tool_in_category(input.tool.name, "admin")
    not is_tool_in_category(input.tool.name, "restricted")
    not is_tool_in_category(input.tool.name, "revoke")
    
    # Tool passes validation rules (if any exist for it)
    tool_passes_validation(input.tool)
}

# Metadata for policy documentation
metadata := {
    "description": "Access control policy for Kubiya tool manager",
    "roles": {
        "admin": "Can access admin tools and revocation tools",
        "user": "Can access general tools except admin and restricted ones"
    },
    "categories": {
        "admin": "Administrative tools for managing access",
        "revoke": "Tools for revoking access",
        "restricted": "Tools with restricted access"
    }
}
EOT

  opa_policy = local.policy_template
}
