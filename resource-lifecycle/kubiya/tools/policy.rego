package kubiya.authz

default allow = false

user_info = {
	groups: ["admin", "user"],
	allowed_secrets: ["secret1", "secret2"],
	allowed_env_vars: ["VAR1", "VAR2"],
}

tool_info = {
	name: input.tool.name,
	args: [key | key := input.tool.args[_]],
	env: input.tool.env,
	integrations: tool_integrations,
}

tool_integrations = {integration |
	some env_var
	env_var = input.tool.env[_]
	integration = determine_integration(env_var)
} union {integration |
	some file
	file = input.tool.files[_]
	integration = determine_integration(file)
}

determine_integration(env_var) = "github" {
	contains(env_var, "GH_TOKEN")
}

determine_integration(file) = "aws" {
	endswith(file, ".aws/credentials")
}

allow_env = true {
	allow_env_vars[env]
	user_info.allowed_env_vars[_] == env
}

allow_secret = true {
	allow_secrets[secret]
	user_info.allowed_secrets[_] == secret
}

allow_integration = true {
	tool_info.integrations[_] == agent_info.integrations[_]
}

allow {
	user_info.groups[_] == "admin"
}

allow {
	user_info.groups[_] == "user"
	allow_env
	allow_secret
	allow_integration
}
