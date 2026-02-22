# 🏦 DevSecOps Banking - AWS Infrastructure

This repository is dedicated to **Phase 3** of the DevSecOps Banking Dashboard project: **Production-Grade Cloud Deployment**. It manages the automated provisioning of a hardened AWS EKS environment using Infrastructure as Code (IaC).

## 📂 Project Context
This project serves as the production landing zone for the 3-tier banking application developed and secured in the previous phases:
* **Phase 1 (App Dev)**: Containerized React, Node.js, and PostgreSQL stack.
* **Phase 2 (Hardening)**: Distroless images, SonarCloud analysis, and Zero-Trust NetworkPolicies.

---

## 🚀 Phase 3: AWS Cloud Infrastructure (Current)

### 🛡️ Security Baseline
* **Private API Endpoint**: The EKS cluster control plane is isolated from the public internet for "Bank-Grade" security.
* **KMS Encryption**: Enforced envelope encryption for K8s Secrets using a dedicated AWS KMS key.
* **Audit Logging**: Full control plane logging (API, Audit, Authenticator) is enabled for compliance.
* **Network Isolation**: All worker nodes are deployed in private subnets with NAT Gateway egress only.

### 🛠️ Prerequisites
* **AWS CLI**: Configured with Administrative access on your ASUS laptop.
* **Terraform**: v1.3+ with AWS Provider v5.x.

### 🏗️ Provisioning Instructions
1.  **Initialize & Upgrade**:
    ```bash
    cd terraform
    terraform init -upgrade
    ```
2.  **Generate Plan**:
    ```bash
    terraform plan -out=eks-prod.tfplan
    ```
3.  **Deploy**:
    ```bash
    terraform apply "eks-prod.tfplan"
    ```

---

## 🧹 Cleanup & Revert
To avoid costs or clear local networking workarounds:
* **Cloud**: `terraform destroy`
* **Windows Port Proxy**: `netsh interface portproxy delete v4tov4 listenaddress=127.0.0.1 listenport=9000`
