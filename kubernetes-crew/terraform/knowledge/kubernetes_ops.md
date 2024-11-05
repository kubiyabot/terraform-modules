# Kubernetes Operations Guide

## Cluster Architecture
### Control Plane Design
The Kubernetes control plane is the backbone of cluster operations. For production environments, a highly available control plane is essential:
- EKS: AWS manages the control plane across 3 availability zones automatically
- GKE: Control plane nodes are managed by Google Cloud in multiple zones
- AKS: Microsoft Azure handles control plane high availability

### Node Management
Production clusters should maintain a minimum of 3-5 worker nodes for high availability. Node sizing recommendations:
- System nodes: Minimum 4 vCPU, 16GB RAM for core system components
- Application nodes: 8 vCPU, 32GB RAM for general workloads
- Memory-intensive workloads: Consider nodes with 64GB+ RAM

### Namespace Organization
Organize workloads into logical namespaces:
- kube-system: Reserved for cluster components
- monitoring: Prometheus, Grafana, and other monitoring tools
- logging: EFK/ELK stack components
- ingress-nginx: Ingress controller and related configs
- cert-manager: Certificate management
- application namespaces: One namespace per application team/environment

## Resource Management
### Quota Management
Implement resource quotas for all namespaces:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
spec:
  hard:
    requests.cpu: "20"
    requests.memory: 40Gi
    limits.cpu: "40"
    limits.memory: 60Gi
```

### Resource Defaults
Set default resource requests and limits:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
spec:
  limits:
  - default:
      memory: 512Mi
      cpu: 500m
    defaultRequest:
      memory: 256Mi
      cpu: 200m
    type: Container
```

## Security Configuration
### Pod Security Standards
Enforce Pod Security Standards based on workload requirements:
- Privileged: Only for system components in kube-system
- Baseline: Default for application workloads
- Restricted: For multi-tenant environments

### Network Policies
Implement default deny and explicit allow policies:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

## Monitoring Setup
### Core Metrics
Essential metrics to monitor:
- Node CPU utilization: Alert threshold at 80%
- Node memory usage: Alert threshold at 85%
- Pod restart count: Alert if > 5 in 15 minutes
- Pod OOMKilled events: Immediate alert
- Persistent volume usage: Alert at 85% capacity

### Logging Configuration
Implement structured logging:
- JSON format for machine parsing
- Include pod, namespace, and container metadata
- Retain logs for 30 days minimum
- Configure log rotation at 100MB per file

## Backup and Recovery
### Backup Strategy
Implement regular backups:
- etcd snapshots: Every 4 hours
- Persistent volumes: Daily incremental, weekly full
- Cluster state: Daily export of all resources
- Retention: 30 days minimum

### Disaster Recovery
Recovery Time Objectives (RTO):
- Critical services: < 1 hour
- Non-critical services: < 4 hours
Recovery Point Objectives (RPO):
- Critical data: < 15 minutes
- Non-critical data: < 24 hours

## Performance Optimization
### HPA Configuration
Configure Horizontal Pod Autoscaling:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Node Affinity
Implement node affinity for workload distribution:
```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-type
          operator: In
          values:
          - application
```

## Maintenance Windows
Schedule maintenance during low-traffic periods:
- Production changes: Tuesday-Thursday, 10:00-16:00 UTC
- Patch updates: First Sunday of each month
- Major upgrades: Quarterly with full testing
- Emergency patches: Immediate with change advisory

## Escalation Procedures
Define clear escalation paths:
1. L1: Platform team on-call (15min response)
2. L2: Senior platform engineers (30min response)
3. L3: Cloud provider support
4. Emergency: CTO/VP Engineering

## Provider-Specific Considerations
${cluster_type == "EKS" ? <<EOT
### AWS EKS
- Use AWS Load Balancer Controller for ingress
- Implement IAM Roles for Service Accounts (IRSA)
- Configure cluster-autoscaler with ASG integration
- Use EBS CSI driver for persistent storage
EOT : ""}

${cluster_type == "GKE" ? <<EOT
### Google GKE
- Use Cloud Load Balancing for ingress
- Implement Workload Identity for service accounts
- Configure cluster-autoscaler with MIG integration
- Use Persistent Disk CSI driver
EOT : ""}

${cluster_type == "AKS" ? <<EOT
### Azure AKS
- Use Application Gateway Ingress Controller
- Implement Azure AD integration for RBAC
- Configure cluster-autoscaler with VMSS
- Use Azure Disk CSI driver
EOT : ""}