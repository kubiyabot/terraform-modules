# Kubernetes Cluster Upgrade Assessment

Please perform a comprehensive upgrade readiness check:

1. Version Analysis:
   - Current cluster version
   - Target version compatibility
   - Component version matrix
   - API deprecation impact

2. Workload Assessment:
   - API version usage
   - Custom resource definitions
   - Storage version compatibility
   - Network policy compatibility

3. Resource Requirements:
   - Node capacity planning
   - Downtime estimation
   - Rollback requirements
   - Backup verification

4. Pre-upgrade Tasks:
   - Backup critical components
   - Update manifests
   - Test environment validation
   - Document rollback procedure

5. Upgrade Strategy:
   - Control plane upgrade steps
   - Worker node upgrade order
   - Workload migration plan
   - Monitoring requirements 