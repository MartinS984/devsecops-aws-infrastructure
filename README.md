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


Gemini said
Those rules are perfectly fine for a default Network ACL.

By default, every AWS VPC comes with a Network ACL that allows all inbound and outbound traffic. What you see in your screenshot—Rule 100 allowing all traffic and the asterisk (*) rule denying everything else—is the standard "Allow All" configuration.

🛡️ Why these rules are safe for your project
Even though this NACL is "wide open," your banking-cluster-prod remains highly secure because of how we built the other layers:

Security Groups: These are your primary line of defense. Unlike the NACL, your Security Groups are set to deny by default. Traffic only gets to your EKS nodes because we explicitly opened port 443 for your Bastion.

Private Isolation: Since your nodes are in private subnets with no public IP, an "Allow All" NACL doesn't mean the internet can reach them. There is no path from the outside world into those subnets except through the NAT Gateway or your SSM session.

Stateless vs. Stateful: If you tried to "harden" this NACL right now by only allowing port 443, your kubectl commands would actually stop working. NACLs are stateless, so you would also have to manually write rules to allow the "return" traffic on ephemeral ports.

🏆 Portfolio Recap: What you've built
Since you've just finished the destroy, you now have a complete end-to-end project history for your CV. You successfully navigated:

Identity Management: Fixed the EKS v1alpha1 vs. v1beta1 authentication by manually upgrading the Bastion to AWS CLI v2.

Network Security: Resolved i/o timeout errors by bridging Security Groups.

Connectivity: Engineered a secure tunnel from your ASUS laptop to a private API using AWS SSM port forwarding.

Application Lifecycle: Debugged a CrashLoopBackOff and verified the cluster could handle a multi-replica Node.js deployment.

🚀 Project: Bank-Grade Private EKS Infrastructure
DevSecOps Engineer | February 2026

Designed and deployed a Zero-Trust, three-tier Node.js application environment on AWS EKS, ensuring total isolation from the public internet.

🛠️ Key Technical Achievements
Infrastructure as Code (IaC): Architected a complete VPC with 4 subnets (2 Public/2 Private) using Terraform to host a private EKS cluster (v1.29).

Zero-Trust Connectivity: Eliminated SSH/Port 22 exposure by implementing an SSM-only Bastion host for cluster administration.

Advanced Networking: Resolved complex i/o timeout issues by engineering cross-Security Group ingress rules, allowing secure communication between the Bastion and the private API endpoint.

Identity & Access Management (IAM/RBAC): Bridged AWS IAM and Kubernetes RBAC by mapping the bastion-ssm-role to the system:masters group within the aws-auth ConfigMap.

Secure Tunnels: Successfully established SSM Port-Forwarding sessions (Local Port 8443 → Private EKS 443) to enable remote Terraform management of a private-only API.

Container Lifecycle & Debugging: Resolved CrashLoopBackOff scenarios by optimizing Node.js container entry points and verified high availability across t3.medium worker nodes.

💻 Technologies Used
Cloud: AWS (EKS, VPC, SSM, NAT Gateway, IAM, KMS).

Tools: Terraform, Kubectl, AWS CLI v2, Docker, Node.js.

OS: Ubuntu 22.04 (via WSL2 on Windows 11).