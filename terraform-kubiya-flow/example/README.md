# Kubiya Module Example

This directory contains an example of how to use the Kubiya Flow Terraform module.

## Usage

1. Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your specific values

3. Initialize Terraform:
```bash
terraform init
```

4. Review the plan:
```bash
terraform plan
```

5. Apply the configuration:
```bash
terraform apply
```

## Required Environment Variables

Before running Terraform, set the Kubiya API key:

```bash
export KUBIYA_API_KEY="your-api-key"
```

## Example Configuration

This example creates:
- A Kubiya teammate with specified email and role
- A Kubiya source (e.g., GitHub integration)
- A Kubiya webhook for notifications

## Variables

See `variables.tf` for a complete list of available variables and their descriptions. 