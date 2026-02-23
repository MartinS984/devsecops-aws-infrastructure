# 🏦 Banking DevSecOps: Private EKS & 3-Tier Node.js Infrastructure

This project implements a "Bank-Grade" production environment on AWS EKS. The core principle is **Zero-Trust Networking**: the cluster API, worker nodes, and databases are strictly private and accessible only through encrypted SSM tunnels.

---

## 🏗️ The Infrastructure Stack
* **VPC**: Custom VPC with 2 Public and 2 Private subnets across multiple AZs.
* **Compute**: EKS Managed Node Group with 2 x `t3.medium` instances.
* **Connectivity**: 
    * No Public EKS Endpoint (Private Only).
    * No SSH (SSM Session Manager only).
    * NAT Gateway for secure outbound internet access (image pulls/updates).

---

## 🛠️ Step-by-Step Debugging & Troubleshooting Ledger

This section tracks the "Real World" hurdles encountered during the February 2026 build.

### 1. Authentication Bridge (AWS CLI v2)
* **The Issue**: `kubectl` failed with `invalid apiVersion "client.authentication.k8s.io/v1alpha1"`.
* **The Cause**: The Ubuntu Bastion had an outdated AWS CLI (v1.x) that didn't support the modern EKS authentication tokens.
* **The Fix**: 
    ```bash
    curl "[https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip](https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip)" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install --update
    /usr/local/bin/aws --version # Must show 2.x
    ```

### 2. Networking "The I/O Timeout"
* **The Issue**: `kubectl get nodes` timed out when reaching the private EKS endpoint.
* **The Cause**: The EKS Cluster Security Group was blocking incoming traffic from the Bastion Security Group.
* **The Fix**: Added a Terraform `aws_security_group_rule` allowing Ingress on port **443** from the Bastion's SG to the EKS Primary SG.

### 3. Identity Crisis (RBAC Mapping)
* **The Issue**: Error: `You must be logged in to the server (Unauthorized)`.
* **The Cause**: Even with network access, the cluster didn't "trust" the Bastion's IAM Role (`bastion-ssm-role`).
* **The Fix**: Updated the EKS module in `main.tf` to manage the `aws-auth` ConfigMap, granting the Bastion role `system:masters` permissions.

### 4. The "Chicken and Egg" Provider Error
* **The Issue**: Terraform apply failed with `connection refused` on `127.0.0.1:80`.
* **The Cause**: The Kubernetes provider on the ASUS laptop couldn't reach the private API to update the ConfigMap.
* **The Fix**: Established an **SSM Tunnel** on port **8443** and configured the provider with `insecure = true` (to bypass the localhost hostname mismatch).

### 5. Application CrashLoopBackOff
* **The Issue**: Node.js pods started but crashed instantly.
* **The Cause**: Standard `node:18-alpine` images exit immediately if no long-running process is started.
* **The Fix**: Implemented a temporary `while true` loop in the `node-app.yaml` manifest to keep the container process alive while testing.

---

## 🚀 Operations Manual

### Establishing the Control Tunnel (Laptop)
Keep this running in a dedicated terminal tab:
```bash
aws ssm start-session \
    --target i-0638482b7fa67b58f \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters '{"host":["10.0.1.216"],"portNumber":["443"],"localPortNumber":["8443"]}'
Managing the Cluster (Bastion)
Bash
# Enter the Bastion
aws ssm start-session --target i-0638482b7fa67b58f

# Deployment Sequence
touch node-app.yaml
nano node-app.yaml
kubectl apply -f node-app.yaml

# Health Checks
kubectl get nodes -o wide
kubectl get pods -w
kubectl logs <pod_name>
🔥 Destruction & Cost Control
To prevent AWS charges (NAT Gateway costs ~$32/month + EKS ~$72/month), destroy the stack when inactive:

Ensure the SSM Tunnel is active.

Run terraform destroy -auto-approve.

Verify the Elastic IP and NAT Gateway are gone in the AWS Console.


---

### 🛡️ One Final DevSecOps Pro-Tip
Since you are planning to destroy the environment, remember that your `terraform.tfstate` file is now the most important file on your ASUS laptop. If you lose it, you'll have to manually delete the AWS resources via the console.

**Would you like me to show you how to set up an S3 Remote Backend for your Terraform state so you can safe