# Dependency Update Analysis

Analyze dependencies for repositories: ${REPOSITORIES}

1. Version Analysis:
   - Outdated packages
   - Breaking changes
   - Security updates
   - Compatibility issues

2. Update Impact:
   - Breaking changes
   - API modifications
   - Build implications
   - Test requirements

3. Security Assessment:
   - Known vulnerabilities
   - Security patches
   - CVE reports
   - Risk evaluation

4. Update Strategy:
   - Priority order
   - Update grouping
   - Testing requirements
   - Rollback plan

Report findings to ${notification_channel} with update recommendations.
If auto_fix_enabled is true, create update PRs for safe updates. 