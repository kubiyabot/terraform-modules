# Databricks Workspace Management

## Workspace Creation Process
1. Azure Resource Requirements
   - Subscription with Contributor access
   - Resource Group (new or existing)
   - Virtual Network with dedicated subnets
   - Network Security Groups

2. Network Configuration
   - Frontend subnet (CIDR: /26 minimum)
   - Backend subnet (CIDR: /26 minimum)
   - NSG rules for Databricks control plane
   - Private Link endpoints (optional)

3. Security Setup
   - Azure AD integration
   - IP Access Lists
   - Encryption settings
   - Credential passthrough
   - Private endpoint configuration

## Best Practices
1. Naming Conventions
   ```
   <env>-dbw-<region>-<purpose>
   Example: prod-dbw-eastus2-analytics
   ```

2. Resource Tagging
   ```
   Environment: prod|dev|staging
   Owner: team-name
   CostCenter: department-id
   Project: project-name
   ```

3. Network Planning
   - Use non-overlapping CIDR ranges
   - Plan for future expansion
   - Consider hub-spoke topology
   - Enable service endpoints

4. Security Guidelines
   - Enable AAD SSO
   - Use managed identities
   - Implement SCIM provisioning
   - Configure audit logging

## Common Issues & Solutions
1. Deployment Failures
   - Verify subscription permissions
   - Check CIDR range conflicts
   - Validate NSG rules
   - Review quota limits

2. Connectivity Issues
   - Verify DNS resolution
   - Check NSG configurations
   - Validate private endpoints
   - Test network routes

3. Performance Optimization
   - Region selection
   - Network throughput
   - Storage configuration
   - Service principal setup 