# Contributing to Kubiya Terraform Modules

Thank you for your interest in contributing to Kubiya Terraform Modules! This document provides guidelines and best practices for contributing to this repository.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Module Development Guidelines](#module-development-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Documentation Standards](#documentation-standards)

## Code of Conduct

This project adheres to the Contributor Covenant Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Getting Started

1. **Fork the repository** to your GitHub account
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/terraform-modules.git
   cd terraform-modules
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/kubiyabot/terraform-modules.git
   ```
4. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## How to Contribute

### Reporting Bugs

- Use the GitHub issue tracker
- Use the bug report template
- Include Terraform version and provider versions
- Provide a minimal reproducible example
- Include relevant logs and error messages

### Suggesting Enhancements

- Use the GitHub issue tracker
- Use the feature request template
- Clearly describe the use case and benefits
- Consider backward compatibility

### Adding New Modules

When creating a new Terraform module:

1. Create a new directory with a descriptive name
2. Follow the standard module structure (see below)
3. Include comprehensive documentation
4. Add examples demonstrating usage
5. Update the main README.md with your module

## Module Development Guidelines

### Standard Module Structure

Each module should follow this structure:

```
<module-name>/
├── terraform/
│   ├── main.tf           # Core resource definitions
│   ├── variables.tf      # Input variables with descriptions
│   ├── outputs.tf        # Output values with descriptions
│   ├── versions.tf       # Terraform and provider version constraints
│   ├── knowledge/        # AI knowledge base (markdown files)
│   ├── prompts/          # Task-specific prompts
│   └── scripts/          # Helper scripts (for webhooks)
├── examples/             # Example usage (optional but recommended)
│   └── basic/
│       ├── main.tf
│       └── README.md
└── README.md             # Module documentation
```

### Terraform Code Standards

1. **Naming Conventions**:
   - Use lowercase letters, numbers, and underscores
   - Use descriptive names for resources and variables
   - Prefix resources with module name when appropriate

2. **Variables**:
   - Always include a description
   - Specify type constraints
   - Provide default values when sensible
   - Mark sensitive variables appropriately

   ```hcl
   variable "example_var" {
     description = "A clear description of what this variable does"
     type        = string
     default     = "default-value"
   }
   ```

3. **Outputs**:
   - Always include a description
   - Mark sensitive outputs appropriately
   - Export useful values for module consumers

   ```hcl
   output "example_output" {
     description = "A clear description of this output"
     value       = resource.example.id
   }
   ```

4. **Resource Definitions**:
   - Use dynamic blocks when appropriate
   - Implement lifecycle rules when needed
   - Use count or for_each for conditional resources

5. **Version Constraints**:
   - Specify minimum Terraform version
   - Specify required provider versions
   - Use pessimistic version constraints

   ```hcl
   terraform {
     required_version = ">= 1.0"

     required_providers {
       kubiya = {
         source  = "kubiya-terraform/kubiya"
         version = "~> 1.0"
       }
     }
   }
   ```

### Knowledge Base Guidelines

For AI knowledge base files:

1. Use clear, descriptive markdown files
2. Include practical examples and use cases
3. Document common troubleshooting steps
4. Keep content focused and relevant
5. Use proper formatting and structure

### Prompt Engineering Guidelines

For AI prompts:

1. Be specific and clear about the task
2. Include context and constraints
3. Specify expected output format
4. Consider edge cases and error handling
5. Test prompts thoroughly before committing

## Pull Request Process

1. **Before Submitting**:
   - Update documentation to reflect any changes
   - Add or update examples as needed
   - Run `terraform fmt` on all modified files
   - Run `terraform validate` to check syntax
   - Test your changes locally
   - Update CHANGELOG.md following Keep a Changelog format

2. **PR Description**:
   - Use the pull request template
   - Clearly describe the changes and motivation
   - Link related issues
   - Include screenshots for UI changes (if applicable)
   - List breaking changes (if any)

3. **Review Process**:
   - Address review feedback promptly
   - Keep the PR focused and atomic
   - Ensure CI checks pass
   - Maintain a clean commit history

4. **Commit Messages**:
   - Use clear and descriptive commit messages
   - Follow conventional commit format:
     - `feat:` for new features
     - `fix:` for bug fixes
     - `docs:` for documentation changes
     - `refactor:` for code refactoring
     - `test:` for test changes
     - `chore:` for maintenance tasks

## Testing Requirements

### Manual Testing

1. **Syntax Validation**:
   ```bash
   terraform fmt -check -recursive
   terraform validate
   ```

2. **Plan Testing**:
   ```bash
   terraform init
   terraform plan
   ```

3. **Apply Testing** (in a safe environment):
   ```bash
   terraform apply
   # Test functionality
   terraform destroy
   ```

### Integration Testing

- Test with different provider versions
- Test with minimum and current Terraform versions
- Verify module works with various input combinations
- Test error handling and edge cases

## Documentation Standards

### Module README

Each module README should include:

1. **Overview**: Brief description of the module's purpose
2. **Prerequisites**: Required tools, accounts, or permissions
3. **Usage**: Basic example showing how to use the module
4. **Inputs**: Table of all input variables
5. **Outputs**: Table of all outputs
6. **Examples**: Links to example implementations
7. **Notes**: Important considerations or limitations

### Code Comments

- Comment complex logic or non-obvious decisions
- Avoid obvious comments
- Keep comments up to date with code changes
- Use TODO comments for known improvements

## Release Process

Module releases follow semantic versioning:

- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

## Questions?

- Check existing issues and documentation
- Ask in GitHub discussions
- Contact the maintainers via the CODEOWNERS file

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

Thank you for contributing to Kubiya Terraform Modules!
