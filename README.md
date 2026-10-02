# ShopEasy DevOps Demo

ShopEasy is a small, fictional e-commerce store built with plain **HTML, CSS and JavaScript**. It exists to teach one lesson:

> **Code Change → Git Commit → Git Push → CI Pipeline → Deployment → Live Application**

## Architecture

```text
Developer
    ↓
GitHub
    ↓
GitHub Actions
    ↓
CI Validation
    ↓
SCP Deployment
    ↓
EC2
    ↓
Nginx
    ↓
ShopEasy
```

Infrastructure:

```text
Terraform
    ↓
AWS
    ↓
EC2
```

> Terraform provisions the EC2 infrastructure.

> GitHub Actions deploys the ShopEasy application to the EC2 infrastructure.

## Project structure

```text
shopeasy/
├── index.html                    # page content (includes the promo banner)
├── styles.css                    # all styling
├── app.js                        # discount + checkout logic
├── .github/workflows/deploy.yml  # CI/CD pipeline
├── README.md
└── .gitignore
```

## EC2 expectations

Terraform has already created an EC2 instance and a security group that allows:

| Port | Purpose | Note |
|------|---------|------|
| 80   | HTTP    | open to the world |
| 22   | SSH     | must be reachable by GitHub Actions (see Troubleshooting) |

**Nginx does not need to be installed in advance.** The first pipeline run installs it, creates `/var/www/shopeasy`, and configures Nginx to serve `/var/www/shopeasy/index.html`. Later runs detect it is already there and skip the install.

### SSH password login must be enabled

The pipeline logs in with a **username and password**. AWS images disable password login by default, so the instance needs it switched on once. Add this to the Terraform `user_data` (Ubuntu):

```bash
#!/bin/bash
echo "ubuntu:CHOOSE_A_STRONG_PASSWORD" | chpasswd
echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/99-password-login.conf
systemctl restart ssh
```

Notes:
- Use the same password you store in the `EC2_PASSWORD` secret. Do not commit it to the repo or to your `.tf` files; pass it to Terraform as a sensitive variable.
- The `99-` file name matters: it is read after the cloud image's own `PasswordAuthentication no` setting, so it wins.
- On Amazon Linux the user is `ec2-user` and the service is `sshd`.
- Password SSH is easier to demo but weaker than key-based login, and port 22 is open to password guessing. Use a strong password and shut the instance down after class.

## Required GitHub secrets

In your repository: **Settings → Secrets and variables → Actions → New repository secret**.

| Secret | What it is |
|--------|-----------|
| `EC2_HOST` | Public IP or public DNS of the EC2 instance created by Terraform. Example: `18.202.45.61` |
| `EC2_USER` | `ubuntu` for Ubuntu, `ec2-user` for Amazon Linux |
| `EC2_PASSWORD` | The password for that user on the EC2 instance. The pipeline also uses it for `sudo` |

Never commit passwords, keys or tokens to this repository.

## Setup guide

### Step 1 — Provision EC2 using Terraform

Run your Terraform project so the instance and security group exist.

### Step 2 — Retrieve the public IP

```bash
terraform output -raw ec2_public_ip
```

### Step 3 — Add GitHub repository secrets

Add `EC2_HOST`, `EC2_USER` and `EC2_PASSWORD` as described above.

### Step 4 — Push the application code

```bash
git add .
git commit -m "Deploy ShopEasy"
git push origin main
```

Watch the run under the **Actions** tab on GitHub.

### Step 5 — Open the site

```text
http://EC2_PUBLIC_IP
```

Confirm ShopEasy loads.

## The pipeline (`deploy.yml`)

```text
Git Push (main)
    ↓
Checkout code
    ↓
Validate files   (test -f ... ; node --check app.js)
    ↓
Prepare server  (install Nginx if missing, create /var/www/shopeasy)
    ↓
Copy index.html, styles.css, app.js to /var/www/shopeasy  (SCP)
    ↓
Reload Nginx  (SSH)
    ↓
Live website updated
```

If the validation step fails, GitHub Actions stops and the later steps never run.

SCP is used instead of `git pull` on the server, so the EC2 instance never needs GitHub credentials.
