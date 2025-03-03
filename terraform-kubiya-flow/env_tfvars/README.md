# Environment Variables

This directory contains environment-specific variable files for different deployment environments.

## Available Environments

- `cicd.tfvars`: Variables for CICD pipeline
- `development.tfvars`: Variables for development environment
- `staging.tfvars`: Variables for staging environment
- `production.tfvars`: Variables for production environment

## Usage

To apply the configuration for a specific environment, use the `-var-file` option:

```bash
# For CICD
terraform apply -var-file="env_tfvars/cicd.tfvars"

# For development
terraform apply -var-file="env_tfvars/development.tfvars"

# For staging
terraform apply -var-file="env_tfvars/staging.tfvars"

# For production
terraform apply -var-file="env_tfvars/production.tfvars"
```

## Environment-Specific Variables

Each environment file contains:
- Agent configuration (name, description, runner, instructions)
- Source configuration (URL)
- Webhook configuration (name, destination, prompt)

## Security Notes

- Never commit sensitive information in these files
- Use environment variables or a secure secrets management system for sensitive values
- Consider using different API keys for different environments 