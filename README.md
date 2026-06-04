# ShipForge Infrastructure

> Terraform infrastructure for a cloud-native microservices platform — provisions a production-grade AWS environment running 50 microservices on EKS, with RDS for persistence and a multi-tier VPC network.

---

## Overview

This repository contains all Terraform code to provision and manage the AWS infrastructure underpinning ShipForge — a 50-microservice platform built on Kubernetes. It covers everything from the network layer up: VPC, EKS cluster, managed RDS database, IAM roles, and supporting services. The goal is a repeatable, version-controlled infrastructure that can be torn down and rebuilt from scratch with a single `terraform apply`.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                          AWS Account                                 │
│                                                                      │
│  ┌──────────────────────── VPC ─────────────────────────────────┐   │
│  │                                                               │   │
│  │   ┌─────────────────┐        ┌──────────────────────────┐    │   │
│  │   │  Public Subnets │        │     Private Subnets       │    │   │
│  │   │  (Multi-AZ)     │        │     (Multi-AZ)            │    │   │
│  │   │                 │        │                           │    │   │
│  │   │  - NAT Gateway  │        │  ┌──────────────────────┐ │    │   │
│  │   │  - Internet GW  │        │  │   EKS Node Groups    │ │    │   │
│  │   └─────────────────┘        │  │   (50 Microservices) │ │    │   │
│  │                              │  └──────────────────────┘ │    │   │
│  │                              │                           │    │   │
│  │                              │  ┌──────────────────────┐ │    │   │
│  │                              │  │   RDS (PostgreSQL)   │ │    │   │
│  │                              │  │   Multi-AZ Subnet    │ │    │   │
│  │                              │  └──────────────────────┘ │    │   │
│  │                              └──────────────────────────┘    │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   ┌──────────────┐   ┌──────────────┐   ┌───────────────────────┐   │
│   │  IAM / IRSA  │   │  ECR         │   │  EBS CSI Driver       │   │
│   │  (per svc)   │   │  (image reg) │   │  (persistent volumes) │   │
│   └──────────────┘   └──────────────┘   └───────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

---

## What Gets Provisioned

| Resource | Details |
|---|---|
| **VPC** | Custom VPC with public and private subnets across multiple AZs, Internet Gateway, NAT Gateway, route tables |
| **EKS Cluster** | Managed Kubernetes cluster with managed node groups sized for 50 microservices |
| **EKS Add-ons** | VPC CNI, CoreDNS, kube-proxy, EBS CSI Driver (with IRSA) |
| **RDS** | PostgreSQL instance in private subnet with subnet group and security groups |
| **IAM** | OIDC provider, IRSA roles for EBS CSI and workloads, node group instance profiles |
| **Security Groups** | EKS cluster SG, node SG, RDS SG with least-privilege ingress/egress rules |
| **ECR** | Container registries for microservice images |
| **Outputs** | Cluster endpoint, kubeconfig data, VPC ID, subnet IDs, RDS endpoint — all exported for downstream use |

---

## Repository Structure

```
shipforge-infra/
├── modules/
│   ├── vpc/              # VPC, subnets, IGW, NAT, route tables
│   ├── eks/              # EKS cluster, node groups, OIDC, add-ons
│   ├── rds/              # RDS instance, subnet group, parameter group
│   └── iam/              # IRSA roles, policies, instance profiles
├── eks.tf                # EKS module call + cluster-level config
├── vpc.tf                # VPC module call
├── RDS.tf                # RDS module call
├── services.tf           # Supporting services (ECR, EBS CSI, etc.)
├── providers.tf          # AWS provider, Terraform version constraints
├── variables.tf          # Input variable declarations
├── terraform.tfvars      # Variable values (DO NOT commit secrets)
├── outputs.tf            # Exported values for downstream consumers
└── .terraform.lock.hcl   # Provider version lock file
```

---

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured (`aws configure`) with sufficient IAM permissions
- `kubectl` for post-provisioning cluster access
- An S3 bucket + DynamoDB table for remote state (recommended)

---

## Usage

### 1. Configure Remote State (Recommended)

Add a backend block to `providers.tf` before the first apply:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-tfstate-bucket"
    key            = "shipforge/infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

### 2. Set Variable Values

Copy and edit the tfvars file:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values — region, cluster name, node sizes, RDS credentials, etc.
```

### 3. Initialize

```bash
terraform init
```

### 4. Plan

```bash
terraform plan -out=tfplan
```

Review the plan carefully — especially IAM and security group changes.

### 5. Apply

```bash
terraform apply tfplan
```

A full provision takes roughly 15–20 minutes (EKS cluster creation dominates).

### 6. Configure kubectl

```bash
aws eks update-kubeconfig \
  --region $(terraform output -raw aws_region) \
  --name $(terraform output -raw cluster_name)
```

### 7. Tear Down

```bash
terraform destroy
```

> **Note:** Delete any PersistentVolumeClaims in the cluster before destroying — EBS volumes created by the CSI driver are not tracked by Terraform and will block VPC deletion.

---

## Key Variables

| Variable | Description | Default |
|---|---|---|
| `aws_region` | AWS region to deploy into | `us-east-1` |
| `cluster_name` | EKS cluster name | `shipforge` |
| `cluster_version` | Kubernetes version | `1.29` |
| `node_instance_type` | EC2 instance type for worker nodes | `t3.medium` |
| `node_desired_size` | Desired number of worker nodes | `3` |
| `node_min_size` | Minimum nodes (for scale-in) | `2` |
| `node_max_size` | Maximum nodes (for scale-out) | `6` |
| `rds_instance_class` | RDS instance type | `db.t3.micro` |
| `rds_db_name` | Initial database name | `shipforge` |
| `vpc_cidr` | CIDR block for the VPC | `10.0.0.0/16` |

---

## Outputs

After `terraform apply`, the following values are exported:

| Output | Description |
|---|---|
| `cluster_endpoint` | EKS API server endpoint |
| `cluster_name` | EKS cluster name |
| `cluster_certificate_authority` | CA data for kubeconfig |
| `vpc_id` | VPC ID |
| `private_subnet_ids` | List of private subnet IDs |
| `public_subnet_ids` | List of public subnet IDs |
| `rds_endpoint` | RDS connection endpoint |
| `ecr_repository_urls` | Map of service name → ECR URL |

---

## Important Notes

### State File Security

`terraform.tfstate` contains sensitive values including RDS credentials and cluster certificates. Never commit it to version control. Use remote state (S3 + DynamoDB) with encryption enabled.

The `.gitignore` for this repo should include:

```
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfvars
```

### EBS CSI Driver OIDC Dependency

The EBS CSI Driver IRSA role references the cluster's OIDC issuer URL, which is generated at cluster creation time. If you rebuild the cluster, the OIDC URL changes and the trust policy must be re-applied:

```bash
terraform apply -target=aws_iam_role.ebs_csi_driver
```

This is a known footgun — see `docs/runbooks/ebs-csi-oidc-drift.md` for the full explanation.

### RDS in Private Subnets

The RDS instance is deployed in private subnets with no public accessibility. To connect during development, use a bastion host or AWS Systems Manager Session Manager port forwarding:

```bash
aws ssm start-session \
  --target <bastion-instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "host=$(terraform output -raw rds_endpoint),portNumber=5432,localPortNumber=5432"
```

---

## Related Repositories

| Repo | Description |
|---|---|
| [shipforge](https://github.com/yourusername/shipforge) | Main platform repo — microservices, GitOps config, observability |

---

## License

MIT
