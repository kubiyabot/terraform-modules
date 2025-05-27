# Changelog

## [Unreleased]

### Changed
- Reverted from script-based webhook management to using the `github_repository_webhook` resource with `for_each` loop
- Added dynamic repository discovery when no repositories are specified
- Improved repository validation using the GitHub provider's data sources
- Fixed issues with repository validation that caused deployment failures
- Fixed circular dependency between GitHub provider and repository discovery
- Replaced `github_repository` data source with more reliable HTTP-based validation to avoid license-related errors
- Enhanced validation to gracefully handle non-existent repositories instead of failing
- Simplified repository specification to only accept repository names without organization prefix
- Made `github_organization` variable mandatory for all use cases

### Added
- Pre-validation script `validate_github_token.sh` to check GitHub token permissions before applying Terraform
- Support for dynamic repository discovery using GitHub API
- Comprehensive README with usage instructions and validation process
- Better error handling for repository access issues
- New `github_organization` variable to explicitly set organization for auto-discovery
- Output for invalid repositories to help identify issues

### Removed
- Complex script-based webhook management that caused reliability issues
- Bash scripts for webhook management that were hard to maintain
- Manual validation steps that were error-prone

## [Previous Version]

### Added
- Initial implementation of CI/CD Maintainer Terraform module
- Script-based webhook management for handling large numbers of repositories
- Webhook validation script for testing repository access 