# Home Lab Stack: DNS, AI Automation & Monitoring

This repository contains the configuration for hosting a secure, private Home Lab stack on a cloud instance (VPS), utilizing Tailscale for network isolation. The stack includes a DNS/Proxy layer, an AI automation layer, and system monitoring.

## Architecture

All services are bound to the Tailscale IP of the host, shielding them from the public internet. We use a **Tailscale Sidecar** architecture, where each major service (or group of services) gets its own Tailscale IP (machine), preventing port conflicts and allowing for clean separation of concerns.

### Core DNS & Proxy Layer
-   **Unbound:** Running as a recursive DNS resolver. It contacts root DNS servers directly rather than forwarding queries to upstream providers like Google or Cloudflare.
-   **Pi-hole:** Network-wide ad blocking. It uses the local Unbound container as its sole upstream DNS. Runs on the `pihole` Tailscale machine.
-   **Nginx Proxy Manager (NPM):** Provides a friendly UI for managing reverse proxies and SSL certificates. Runs on the `npm` Tailscale machine.

### AI & Automation Layer
-   **Ollama:** Local AI model serving. Pre-configured to pull models like `llama3.1:8b` and `qwen2.5-coder:7b`. Runs on the `ollama` Tailscale machine.
-   **Open WebUI:** A ChatGPT-like interface for interacting with the Ollama models. Supports RAG, voice, and user accounts. Runs on the `open-webui` Tailscale machine.
-   **n8n:** Workflow automation tool for integrating AI with other services. Runs on the `n8n` Tailscale machine.
-   **PostgreSQL (with pgvector):** Database backend for n8n, using `pgvector` for native AI memory and vector store capabilities.

### Security & Monitoring Layer
-   **Authelia:** An open-source authentication server providing Single Sign-On (SSO) and Two-Factor Authentication (2FA). Integrates with Nginx Proxy Manager to protect exposed services. Runs on the `authelia` Tailscale machine.
-   **Uptime Kuma:** Self-hosted monitoring tool for tracking the uptime of services. Runs on the `uptime-kuma` Tailscale machine.

## Directory Structure

```
.
├── config/
│   ├── unbound/       # Unbound configuration files
│   ├── pihole/        # Placeholders for mapped config volumes
│   ├── npm/           # Placeholders for mapped config volumes
│   └── authelia/      # Authelia configuration files
├── data/
│   ├── pihole/        # Persistent data for Pi-hole
│   ├── npm/           # Persistent data for NPM
│   ├── n8n/           # Persistent data for n8n
│   ├── ollama/        # Persistent data for Ollama models
│   ├── postgres/      # Persistent data for PostgreSQL
│   ├── uptime-kuma/   # Persistent data for Uptime Kuma
│   └── open-webui/    # Persistent data for Open WebUI
├── .github/workflows/ # CD Pipeline
└── docker-compose.yml # Service definitions
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

### 3. GitHub Secrets

Add the following **Secrets** to your GitHub repository (`Settings` -> `Secrets and variables` -> `Actions`):

| Secret Name       | Description                                                                 |
| ----------------- | --------------------------------------------------------------------------- |
| `TS_OAUTH_CLIENT_ID` | Tailscale OAuth Client ID (Description: "GitHub Actions", Tag: `tag:ci`). |
| `TS_OAUTH_SECRET` | Tailscale OAuth Client Secret.                                              |
| `SSH_HOST`        | The **Tailscale IP address** of your server (e.g., `100.x.y.z`).            |
| `SSH_USERNAME`    | The SSH username (e.g., `sysadmin` or `ubuntu`).                            |
| `SSH_PRIVATE_KEY` | Your private SSH key (PEM format) used to access the instance.              |
| `TS_AUTHKEY`      | **Required**. A **Reusable** Tailscale Auth Key (Tags: `tag:server` recommended). |
| `TAILSCALE_IP`    | The Tailscale IP address of your server instance (e.g., `100.x.y.z`).       |
| `PIHOLE_PASSWORD` | (Optional) Password for the Pi-hole Web Interface. Defaults to `admin`.     |

### 4. Deployment

Push to the `main` branch. The workflow will:
1.  Join the Tailscale network (as `tag:ci`).
2.  Connect to your server via SSH over the private tunnel.
3.  Clean up old config (`rm -rf config docker-compose.yml`) in `/lab/docker/cloudlab` while preserving `data/`.
4.  Deploy the new configuration and restart services.

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

To verify DNS via Unbound:
```bash
dig @<TAILSCALE_IP> google.com
```

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

-   **Configuration Changes:** Edit `config/unbound/unbound.conf` locally and push to GitHub. The pipeline will update the file and restart containers.
-   **Updates:** The `docker-compose.yml` uses `latest` tags. Restarting the stack (or re-running the pipeline) will pull new images if available.

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
