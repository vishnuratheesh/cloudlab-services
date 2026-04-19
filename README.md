# Cloud Lab Stack: DNS, AI Automation & Monitoring

[![Deploy to Cloudlab](https://github.com/vishnuratheesh/cloudlab-services/actions/workflows/deploy.yml/badge.svg)](https://github.com/vishnuratheesh/cloudlab-services/actions/workflows/deploy.yml)

This repository contains the configuration for hosting a secure, private Home Lab stack on a cloud instance (VPS), utilizing Tailscale for network isolation. The stack includes a DNS/Proxy layer, an AI automation layer, and system monitoring.

## Tech Stack

![Tailscale](https://img.shields.io/badge/Tailscale-FFFFFF?style=for-the-badge&logo=Tailscale&logoColor=black)
![Docker](https://img.shields.io/badge/Docker-2CA5E0?style=for-the-badge&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Authelia](https://img.shields.io/badge/Authelia-1A2C37?style=for-the-badge&logo=authelia&logoColor=white)
![Nginx Proxy Manager](https://img.shields.io/badge/Nginx_Proxy_Manager-009639?style=for-the-badge&logo=nginx&logoColor=white)
![Pi-Hole](https://img.shields.io/badge/Pi--Hole-F50D30?style=for-the-badge&logo=pi-hole&logoColor=white)
![n8n](https://img.shields.io/badge/n8n-FF6C37?style=for-the-badge&logo=n8n&logoColor=white)
![Ollama](https://img.shields.io/badge/Ollama-FFFFFF?style=for-the-badge&logo=Ollama&logoColor=black)

## Architecture

The stack is designed with a **Layered Architecture** and uses a **Tailscale Sidecar** pattern. Every major service is accompanied by a Tailscale container, granting it a unique identity and IP on your private Tailnet. This shields all services from the public internet.

The configuration is divided into logical layers (located in the `compose/` directory), which are connected via a shared external Docker network (`lab_network`).

### 1. Network Layer (`compose/network`)
-   **Unbound:** Recursive DNS resolver. Contacts root DNS servers directly.
-   **Pi-hole:** Network-wide ad blocking. Uses local Unbound as its upstream DNS. Runs on the `pihole` Tailscale machine.
-   **Nginx Proxy Manager (NPM):** Reverse proxy for exposing specific services to domains if necessary. Runs on the `npm` Tailscale machine.
-   **Authelia:** SSO and 2FA authentication server. Runs on the `authelia` Tailscale machine.

### 2. Data Layer (`compose/data`)
-   **PostgreSQL (with pgvector):** Database backend for n8n and vector store for AI memory.

### 3. AI Core Layer (`compose/ai-core`)
-   **Ollama:** Local AI model serving (`llama3.1:8b`, `qwen2.5-coder:7b`). Runs on the `ollama` Tailscale machine.
-   **LiteLLM:** Unified API proxy to route requests to Ollama and track usage/costs. Runs on the `litellm` Tailscale machine.

### 4. AI Apps Layer (`compose/ai-apps`)
-   **Open WebUI:** ChatGPT-like interface for Ollama. Supports RAG, voice, and user accounts. Runs on the `open-webui` Tailscale machine.
-   **SearxNG:** Privacy-respecting metasearch engine used by the AI to search the live web. Runs on the `searxng` Tailscale machine.
-   **Flowise:** Visual UI builder for advanced AI agent logic and RAG workflows. Runs on the `flowise` Tailscale machine.

### 5. Automation Layer (`compose/automation`)
-   **n8n:** Workflow automation tool connecting apps and AI. Runs on the `n8n` Tailscale machine.

### 6. Management Layer (`compose/management`)
-   **Uptime Kuma:** Uptime tracking and alerts. Runs on the `uptime-kuma` Tailscale machine.
-   **Dockge:** Web-based Docker Compose management console. Allows you to view logs, start/stop layers, and monitor the `compose/` directory live. Runs on the `dockge` Tailscale machine.

## Directory Structure

```
.
├── compose/           # Segmented Docker Compose layers
│   ├── network/
│   ├── data/
│   ├── ai-core/
│   ├── ai-apps/
│   ├── automation/
│   └── management/
├── config/            # Static configuration files (Unbound, Authelia, LiteLLM, SearxNG)
├── data/              # Persistent volumes (Ignored in Git, preserved during deployment)
├── docs/              # Markdown Wiki and Roadmap documentation
└── .github/workflows/ # CD Pipeline
```

## Setup & Deployment

### 1. Prerequisites

-   A Cloud Instance (Ubuntu/Linux).
-   Tailscale installed and running on the instance.
-   Docker and Docker Compose installed on the instance.
-   A GitHub repository with this code.

### 2. Tailscale & Server Setup (One-time)

This deployment uses **GitOps with Tailscale**, meaning the GitHub Runner joins your private network to deploy securely.

#### A. Tailscale ACLs
Update your Tailscale Access Controls to allow the `tag:ci` tag to SSH into your server (`tag:server`).

```json
// In "tagOwners":
"tagOwners": {
  "tag:ci": ["autogroup:admin"],
},

// In "ssh":
"ssh": [
  {
    "action": "accept",
    "src": ["tag:ci"],
    "dst": ["tag:server"],
    "users": ["sysadmin", "ubuntu"] // Match your server user
  }
],
```

#### B. Server SSH Keys
Ensure the public key corresponding to `SSH_PRIVATE_KEY` is in `~/.ssh/authorized_keys` on your server.

#### C. Directory Setup
Create the target directory for deployment and ensure the deployment user owns it:

```bash
sudo mkdir -p /lab/docker
sudo chown -R <username>:<username> /lab/docker
```

### 3. GitHub Secrets (Keys to Set)

Add the following **Secrets** to your GitHub repository (`Settings` -> `Secrets and variables` -> `Actions`). The pipeline will not deploy without these properly set.

| Secret Name | Description | How to Generate / Where to Get |
| :--- | :--- | :--- |
| `TS_OAUTH_CLIENT_ID` | Tailscale OAuth Client ID (Tag: `tag:ci`). | Tailscale Admin Console -> Settings -> OAuth clients. Create one for "GitHub Actions". |
| `TS_OAUTH_SECRET` | Tailscale OAuth Client Secret. | Generated along with the OAuth Client ID above. |
| `TS_AUTHKEY` | **Required**. A **Reusable** Tailscale Auth Key. | Tailscale Admin Console -> Settings -> Keys. Generate a "Reusable" key. **Important:** Copy the string starting with `tskey-auth-` immediately. Do *not* use the Key ID (e.g., `k31Uz...`). |
| `TAILSCALE_IP` | The **Tailscale IP address** of your server. | Look for your server's 100.x.y.z IP in the Tailscale Admin Console. |
| `SSH_HOST` | The server's Tailscale IP address. | Same as `TAILSCALE_IP` (e.g., `100.x.y.z`). |
| `SSH_USERNAME` | The SSH username for the server deployment user. | E.g., `sysadmin` or `ubuntu` depending on your OS. |
| `SSH_PRIVATE_KEY` | Your private SSH key (PEM format). | Generate via `ssh-keygen -t ed25519` on your local machine and copy the private part. Add the public part to the server's `~/.ssh/authorized_keys`. |
| `PIHOLE_PASSWORD` | Password for the Pi-hole Web Interface. | Any secure password. Defaults to `admin` if not provided. |
| `AUTHELIA_JWT_SECRET` | Secret for Authelia JWT tokens. | Run `openssl rand -hex 64` in your terminal. |
| `AUTHELIA_SESSION_SECRET` | Secret for Authelia Session cookies. | Run `openssl rand -hex 64` in your terminal. |
| `AUTHELIA_STORAGE_ENCRYPTION_KEY`| Secret for Authelia local DB encryption. | Run `openssl rand -hex 64` in your terminal. |
| `AUTHELIA_ADMIN_PASSWORD_HASH`| Argon2 hash for your Authelia Admin. | Run: `docker run authelia/authelia:4.38.8 authelia crypto hash generate argon2 --password 'YOUR_PASSWORD'` |
| `WEBUI_SECRET_KEY` | Secret Key for Open WebUI sessions. | Run `openssl rand -hex 32` in your terminal. |

### 4. Deployment

Push to the `main` branch. The workflow will:
1.  Join the Tailscale network (as `tag:ci`).
2.  Connect to your server via SSH over the private tunnel.
3.  Clean up old config (`rm -rf config docker-compose.yml compose`) in `/lab/docker/cloudlab` while preserving `data/`.
4.  Deploy the new configuration and restart all stacks in logical order.

### 5. Verification

After deployment, connect to your Tailscale network on your local machine. You can access the services via their Tailscale machine names (if MagicDNS is enabled) or their Tailscale IPs.

-   **NPM (Nginx Proxy Manager):**
    -   Admin Interface: `http://npm:81`
    -   Default Login: `admin@example.com` / `changeme`

-   **Pi-hole:**
    -   Web Interface: `http://pihole/admin`

-   **Open WebUI (AI Dashboard):**
    -   Web Interface: `http://open-webui:8080`
    -   Requires initial setup to create an admin account. Connected to Ollama automatically.

-   **Authelia (SSO & 2FA):**
    -   Web Interface: `http://authelia:9091`
    -   (Requires configuring `config/authelia/configuration.yml` with your users and policies first).

-   **n8n (Workflow Automation):**
    -   Web Interface: `http://n8n:5678`
    -   Requires initial setup to create an admin account.

-   **Ollama (AI Models):**
    -   API Endpoint: `http://ollama:11434`
    -   Verify models are pulled: `curl http://ollama:11434/api/tags`

-   **Uptime Kuma (Monitoring):**
    -   Web Interface: `http://uptime-kuma:3001`
    -   Requires initial setup to create an admin account.

-   **Dockge (Management Console):**
    -   Web Interface: `http://dockge:5001`
    -   Requires initial setup to create an admin account. Allows managing the `compose/` stacks.

-   **LiteLLM (AI Proxy):**
    -   API Endpoint: `http://litellm:4000`

-   **SearxNG (Web Search):**
    -   Web Interface: `http://searxng:8080`

-   **Flowise (AI Logic Builder):**
    -   Web Interface: `http://flowise:3000`

To verify DNS via Unbound:
```bash
dig @<TAILSCALE_IP> google.com
```


### Post-Deployment Service Setup Guide

Now that your infrastructure is deployed and running securely over Tailscale, it’s time to perform the initial setup for each service. Follow these steps to configure your newly deployed lab.

#### 1. Nginx Proxy Manager (NPM)
NPM is your gateway for routing traffic via reverse proxy. While you may be using Tailscale primarily, NPM is useful if you expose services or just want internal domain routing.
1. **Access the Admin Panel**: Navigate to `http://npm:81` in your browser.
2. **Initial Login**: Use the default credentials:
   - **Email**: `admin@example.com`
   - **Password**: `changeme`
3. **Change Credentials**: Immediately upon login, you will be prompted to update the admin email and create a new, secure password.
4. **Add a Proxy Host** (Optional): Click "Proxy Hosts" > "Add Proxy Host" to route domains to your internal containers.

#### 2. Pi-hole
Pi-hole acts as your network-wide ad blocker and local DNS resolver.
1. **Access the Web Interface**: Navigate to `http://pihole/admin` (or `https://pihole.<your-tailnet>.ts.net/admin` if you configured Tailscale HTTPS).
2. **Login**: Click "Login" on the left sidebar. Use the password you set in your `PIHOLE_PASSWORD` GitHub secret. If you didn't set one, it defaults to `admin`.
3. **Set Up Upstream DNS**: Go to **Settings > DNS**. Unbound is pre-configured as your custom upstream (`unbound#53`). Ensure this is selected and the standard upstream providers (like Google or Cloudflare) are unchecked.
4. **Update Adlists**: Go to **Adlists** on the left menu, ensure the default list is active, and click **Tools > Update Gravity** to pull the latest blocklists.

#### 3. Authelia (SSO & 2FA)
Authelia provides Single Sign-On and Two-Factor Authentication for your services. You manage users via a configuration file.
1. **Create an Admin Password Hash**: On your local machine (with Docker installed), generate an Argon2 hash for your admin password:
   ```bash
   docker run authelia/authelia:4.38.8 authelia crypto hash generate argon2 --password 'your_strong_password'
   ```
2. **Add Users**: Your users are managed in `data/authelia/users_database.yml` (and some config in `config/authelia/configuration.yml`). Edit `data/authelia/users_database.yml` on the server or via your local codebase (and push via CI). Example of a user entry:
   ```yaml
   users:
     yourusername:
       displayname: "Your Name"
       # Paste the hash generated in Step 1 here:
       password: "$argon2id$v=19$m=65536,t=3,p=4$..."
       email: you@example.com
       groups:
         - admins
         - dev
   ```
3. **Access Authelia**: Navigate to `http://authelia:9091` and log in with the credentials you just configured to register your first 2FA device (like a YubiKey or Authenticator App).

#### 4. Open WebUI (AI Dashboard)
Open WebUI is your frontend for interacting with Ollama and other AI models.
1. **Access the Interface**: Navigate to `http://open-webui:8080`.
2. **Create Admin Account**: The first account registered automatically becomes the Administrator. Click "Sign Up", enter your name, email, and a secure password.
3. **Verify Ollama Connection**: Go to **Settings (gear icon) > Connections**. Verify that the Ollama URL is set to `http://ollama:11434` and shows as connected. You can pull models directly from this UI.

#### 5. n8n (Workflow Automation)
n8n allows you to build powerful automation workflows, connecting your AI models with external APIs.
1. **Access the Interface**: Navigate to `http://n8n:5678`.
2. **Initial Setup**: You will be prompted to create an owner account. Enter your details and set up your initial workspace.
3. **Connect to Local AI**: To use Ollama in your workflows, add an **Ollama** credential in n8n and set the Base URL to `http://ts-ollama:11434` (using the sidecar's Docker network name).

#### 6. Uptime Kuma (Monitoring)
Uptime Kuma monitors the health of your infrastructure.
1. **Access the Dashboard**: Navigate to `http://uptime-kuma:3001`.
2. **Create Admin Account**: On your first visit, you must create an admin username and password.
3. **Add a Monitor**: Click "Add New Monitor". Set the type to "HTTP(s)", name it (e.g., "Open WebUI"), and set the URL to `http://open-webui:8080`. Set the heartbeat interval to check if your services are healthy!

#### 7. Dockge (Compose Management)
Dockge provides a web UI to manage your Docker Compose stacks.
1. **Access the Console**: Navigate to `http://dockge:5001`.
2. **Initial Setup**: Create your admin account on the welcome screen.
3. **Manage Stacks**: You will see your layered compose files (e.g., `network`, `ai-core`). You can view live logs, restart containers, or monitor resource usage directly from this UI. *(Note: While you can edit compose files here, remember that your GitHub repository is the single source of truth for deployments!)*


## Tutorials: Connecting to the AI Stack

Because your services are on a Tailscale network, you can securely connect your local tools directly to the remote AI models without exposing ports to the internet.

### 1. Connecting VSCode (Continue Extension)
The [Continue](https://continue.dev/) extension for VSCode allows you to use your remote Ollama instance as a coding assistant (like GitHub Copilot).

1. Install the **Continue** extension in VSCode.
2. Open the Continue settings (`~/.continue/config.json`).
3. Add your remote Ollama instance to the `models` array using the Tailscale IP or MagicDNS name:
   ```json
   {
     "models": [
       {
         "title": "Remote Qwen Coder",
         "provider": "ollama",
         "model": "qwen2.5-coder:7b",
         "apiBase": "http://ollama:11434"
       }
     ]
   }
   ```

### 2. Connecting Standalone Chat Clients
You can use beautiful native apps like [Chatbox](https://chatboxai.app/) or [LobeChat](https://lobehub.com/) on your laptop/phone to talk to your models.

1. Download and open the chat client.
2. Go to Settings > Model Providers.
3. Select **Ollama**.
4. Set the API URL to: `http://ollama:11434` (or `http://<your-ollama-tailscale-ip>:11434`).
5. The client will automatically fetch the available models (`llama3.1:8b`, `qwen2.5-coder:7b`, etc.).

### 3. Integrating Ollama with n8n
To build AI workflows in n8n using your local models:
1. Open n8n (`http://n8n:5678`).
2. Go to **Credentials** -> **Add Credential** -> Search for **Ollama API**.
3. Set the **Base URL** to `http://ts-ollama:11434` (Note: we use `ts-ollama` because n8n uses Docker's internal network to reach the sidecar, which then forwards to Ollama).

## Maintenance

-   **Configuration Changes:** Edit `compose/<layer>/compose.yaml` or files in `config/` locally and push to GitHub. The pipeline will update the files and restart containers.
-   **Updates:** The `compose.yaml` files use `latest` tags. Restarting the stack via Dockge or re-running the pipeline will pull new images if available.

## Troubleshooting

### Port 53 Already in Use

If the deployment fails with `Error: bind: address already in use` for port 53, it is likely that `systemd-resolved` (default on Ubuntu) is listening on that port. To fix this, you need to disable the system stub listener on the host:

1.  **Edit `resolved.conf`:**
    ```bash
    sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
    ```
2.  **Restart the service:**
    ```bash
    sudo systemctl restart systemd-resolved
    ```

### Kernel Buffer Limits (Unbound Warnings)

If you see warnings like `so-rcvbuf 1048576 was not granted` or `so-sndbuf 4194304 was not granted` in the Unbound logs, it means the host system's kernel buffer limits are lower than what Unbound is requesting (1MB receive, 4MB send).

To fix this properly, you need to increase the limits on the host machine.

1.  **Check current limits:**
    ```bash
    sysctl net.core.rmem_max
    sysctl net.core.wmem_max
    ```

2.  **Apply new limits temporarily:**
    ```bash
    sudo sysctl -w net.core.rmem_max=1048576
    sudo sysctl -w net.core.wmem_max=4194304
    ```

3.  **Make them persistent:**
    Add the following lines to `/etc/sysctl.conf`:
    ```
    net.core.rmem_max=1048576
    net.core.wmem_max=4194304
    ```
    Then run `sudo sysctl -p` to apply changes.
