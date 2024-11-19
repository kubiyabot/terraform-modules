# 🛡️ AWS JIT Permissions Guardian

> Transform your AWS access management with AI-powered, Just-In-Time permissions control

![image](https://github.com/user-attachments/assets/04ce2ba1-18ec-408d-ab4a-42850830e25d)

## 🌟 Overview

AWS JIT Permissions Guardian revolutionizes AWS access management by providing secure, temporary, and AI-driven access control. It ensures least-privilege access while maintaining operational efficiency through automated workflows and intelligent policy management.

## 🏗️ Architecture & Workflow

```mermaid
flowchart TD
    User([User])
    Slack[Slack Interface]
    Guardian[JIT Guardian]
    Policy[Policy Engine]
    Approvers[Approvers Channel]
    AWS[AWS IAM]

    User --> Slack
    Slack --> Guardian
    Guardian --> Policy
    Policy --> Approvers
    Approvers --> Guardian
    Guardian --> AWS
    AWS --> User

    classDef user fill:#f9d71c,stroke:#333,stroke-width:2px
    classDef slack fill:#4A154B,stroke:#333,stroke-width:2px,color:white
    classDef guardian fill:#3498db,stroke:#333,stroke-width:2px,color:white
    classDef policy fill:#2ecc71,stroke:#333,stroke-width:2px,color:white
    classDef approvers fill:#e74c3c,stroke:#333,stroke-width:2px,color:white
    classDef aws fill:#FF9900,stroke:#333,stroke-width:2px

    class User user
    class Slack slack
    class Guardian guardian
    class Policy policy
    class Approvers approvers
    class AWS aws
```

## 🔑 Key Components

### Policy Management Flow
```mermaid
flowchart LR
    Policies[(Policies)]
    Engine[Engine]
    Temp[Temp Access]
    IAM[AWS IAM]

    Policies --> Engine
    Engine --> Temp
    Temp --> IAM

    classDef policies fill:#f9d71c,stroke:#333,stroke-width:2px
    classDef engine fill:#3498db,stroke:#333,stroke-width:2px,color:white
    classDef temp fill:#2ecc71,stroke:#333,stroke-width:2px,color:white
    classDef iam fill:#FF9900,stroke:#333,stroke-width:2px

    class Policies policies
    class Engine engine
    class Temp temp
    class IAM iam
```

### Approval Process
```mermaid
sequenceDiagram
    actor User
    participant Guardian
    participant Approvers
    participant AWS

    User->>Guardian: Request
    Guardian->>Approvers: Forward
    Approvers->>Guardian: Approve
    Guardian->>AWS: Apply
    AWS->>User: Grant
```

## 🔄 Request Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Requested
    Requested --> Validating
    Validating --> PolicyGeneration
    PolicyGeneration --> ApprovalPending
    ApprovalPending --> AccessGranted: Approved
    ApprovalPending --> AccessDenied: Rejected
    AccessGranted --> AccessExpired: TTL
    AccessExpired --> [*]
    AccessDenied --> [*]
```

## 📊 Access Analytics

```mermaid
flowchart TD
    Requests[Requests]
    Analytics[Analytics]
    Patterns[Patterns]
    Usage[Usage]
    Security[Security]

    Requests --> Analytics
    Analytics --> Patterns
    Analytics --> Usage
    Analytics --> Security

    classDef requests fill:#f9d71c,stroke:#333,stroke-width:2px
    classDef analytics fill:#3498db,stroke:#333,stroke-width:2px,color:white
    classDef patterns fill:#2ecc71,stroke:#333,stroke-width:2px,color:white
    classDef usage fill:#e74c3c,stroke:#333,stroke-width:2px,color:white
    classDef security fill:#9b59b6,stroke:#333,stroke-width:2px,color:white

    class Requests requests
    class Analytics analytics
    class Patterns patterns
    class Usage usage
    class Security security
```

## ⚙️ Technical Stack

* **Infrastructure**: Terraform
* **Runtime**: Kubiya Runner (Kubernetes)
* **Integration**: AWS IAM, Slack, Okta
* **AI Engine**: GPT-4
* **Storage**: SQLite (for request tracking)

## 🚨 Prerequisites

### Required Configuration

* Kubiya Runner (Kubernetes Cluster)
* AWS IAM Permissions
* Slack Workspace
* Okta Groups Configuration
* Approvers Channel

### ⚡ Policy Configuration (YAML)

```json
{
  "policies": [
    {
      "policy_name": "ReadOnlyAccess",
      "aws_account_id": "123456789012",
      "request_name": "Read Only Access"
    }
  ]
}
```

> ⚠️ **IMPORTANT**: The Guardian requires a valid policy configuration to function. Without properly configured available policies, the system will not process access requests.

## 🚀 Deployment

### Quick Start (Recommended)
The easiest way to deploy AWS JIT Permissions Guardian is through the Kubiya web interface or API:

1. Visit [Kubiya Use Cases](https://docs.kubiya.ai/docs/get-started/choose-a-use-case-and-identify-prerequisites)
2. Select "AWS JIT Permissions Guardian" use case
3. Follow the guided setup process

This method automatically handles all infrastructure provisioning and configuration for you.

### Advanced Deployment (Optional)
For teams who prefer managing their infrastructure as code directly, you can use any terraform flavor:

#### 1. Configure Variables
```hcl
teammate_name           = "jit-guardian"
kubiya_runner          = "your-cluster"
approvers_slack_channel = "#aws-access-approvers"
multiline_available_policies = jsonencode({
  policies = [
    {
      policy_name     = "ReadOnlyAccess"
      aws_account_id  = "123456789012"
      request_name    = "Read Only Access"
    }
  ]
})
```

#### 2. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

## 🔐 Access Control

### Okta Groups
* Only members of specified Okta groups can request access
* Groups are defined in `allowed_okta_groups` variable
* Access requests from users outside these groups will be automatically rejected

### Request Flow
1. User (from allowed Okta group) requests access
2. Guardian validates Okta group membership
3. Request forwarded to approvers channel
4. Approvers review and decide
5. Access granted/denied based on approval

## 🎯 Best Practices

### Policy Configuration
* Define clear policy names
* Use descriptive request names
* Keep policies minimal

### Approval Process
* Set up dedicated approvers channel
* Define clear approval criteria
* Document approval decisions

### Access Management
* Use time-bound access
* Monitor access patterns
* Regular policy reviews

## 🔍 Troubleshooting

### Common Issues and Solutions

#### Policy Not Found
* Verify policy configuration
* Check AWS account ID
* Validate policy name

#### Approval Timeout
* Check approvers channel
* Verify approver permissions
* Review notification settings

## 📚 Additional Resources

* [Kubiya Documentation](https://docs.kubiya.ai)
* [AWS IAM Best Practices](https://aws.amazon.com/iam/best-practices/)
* [Okta Integration Guide](https://docs.kubiya.ai/integrations/okta)
* [Terraform Documentation](https://terraform.io/docs)

---

> 🔐 Secure by default, simple by design

Built with ❤️ by [Kubiya.ai](https://kubiya.ai)
