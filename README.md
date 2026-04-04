# Kiwi TCMS Quick Deployment

This repository provides everything you need to quickly deploy **Kiwi TCMS Free Edition** across multiple cloud providers using modern Infrastructure-as-code (IaC) tools.

## 🚀 Quick Start

Deploying Kiwi TCMS involves two main steps:
1.  **Build an Image** (Optional but recommended): Use Packer to create a pre-configured VM image with Docker and dependencies.
2.  **Provision Infrastructure**: Use Terraform, CloudFormation, Pulumi, or ARM templates to deploy the VM and start Kiwi TCMS via Docker Compose.

---

## 📂 Project Structure

```text
.
├── cloudformation/      # AWS CloudFormation templates
├── azure/               # Azure ARM templates
├── packer/              # Packer HCL & Ansible playbooks
├── terraform/           # Terraform modules for AWS, DO, Azure, GCP
├── pulumi/              # Pulumi programs (TypeScript)
├── docker-compose.yml   # Core Kiwi TCMS configuration
└── env.example          # Template for environment variables
```

---

## 🛠 Prerequisites

-   [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/)
-   [Packer](https://www.packer.io/downloads) (for building images)
-   Cloud CLI & Credentials (AWS CLI, doctl, az CLI, gcloud)
-   IaC Tools: [Terraform](https://www.terraform.io/downloads), [Pulumi](https://www.pulumi.com/docs/get-started/install/)

---

## 📦 1. Build Custom Images (Packer)

Building a custom image ensures all dependencies are pre-installed.

### AWS AMI
```bash
cd packer
packer init aws-kiwitcms.pkr.hcl
packer build aws-kiwitcms.pkr.hcl
```

### DigitalOcean Snapshot
```bash
cd packer
export DIGITALOCEAN_TOKEN="your_token"
packer init digitalocean-kiwitcms.pkr.hcl
packer build digitalocean-kiwitcms.pkr.hcl
```

---

## 🏗 2. Provision Infrastructure

### Using Terraform (Recommended)
Each provider has its own directory under `terraform/`.

```bash
cd terraform/aws
terraform init
terraform apply -var="ami_id=ami-xxxx" -var="key_name=my-key" -var="db_password=secure_pass"
```

### Using Pulumi
Pulumi provides a programmatic approach to infrastructure.

```bash
cd pulumi/aws
npm install
pulumi up
```

---

## ⚙️ Post-Deployment Setup

Once your instance is running, you need to initialize the Kiwi TCMS database and create an admin user.

1.  **SSH into your instance**:
    ```bash
    ssh ubuntu@<your-instance-ip>
    ```

2.  **Initialize Kiwi TCMS**:
    ```bash
    cd kiwitcms
    docker exec -it kiwi_web /Kiwi/manage.py initial_setup
    ```

3.  **Access the Dashboard**:
    Open `https://<your-instance-ip>` in your browser.

---

## 🔒 Security Recommendations

-   **Passwords**: Change the `KIWI_DB_PASSWORD` in your `.env` or IaC variables immediately.
-   **Firewall**: The templates open ports 22, 80, and 443. For production, restrict port 22 to your specific IP.
-   **SSL**: Kiwi TCMS comes with a self-signed certificate. For production, consider using a reverse proxy with Let's Encrypt.

---

## 🤝 Contributing

Feel free to open issues or submit pull requests for other cloud providers or improvements!
