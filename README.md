# Home DNS Stack: Pi-hole + Unbound + Nginx Proxy Manager

This repository contains the configuration for hosting a secure, private DNS and Proxy stack on an Oracle Cloud Free Tier instance, utilizing Tailscale for network isolation.

## Architecture

-   **Tailscale:** Provides the secure, private network layer. All services are bound to the Tailscale IP of the host, shielding them from the public internet.
-   **Unbound:** Running as a recursive DNS resolver. It contacts root DNS servers directly rather than forwarding queries to upstream providers like Google or Cloudflare.
-   **Pi-hole:** Network-wide ad blocking. It uses the local Unbound container as its sole upstream DNS.
-   **Nginx Proxy Manager (NPM):** Provides a friendly UI for managing reverse proxies and SSL certificates (if needed).

## Directory Structure

```
.
├── config/
│   ├── unbound/       # Unbound configuration files
│   ├── pihole/        # Placeholders for mapped config volumes
│   └── npm/           # Placeholders for mapped config volumes
├── data/
│   ├── pihole/        # Persistent data for Pi-hole
│   ├── npm/           # Persistent data for NPM
│   └── ...
├── .github/workflows/ # CD Pipeline
└── docker-compose.yml # Service definitions
```

## Setup & Deployment

### 1. Prerequisites

-   An Oracle Cloud Instance (Ubuntu/Linux).
-   Tailscale installed and running on the instance.
-   Docker and Docker Compose installed on the instance.
-   A GitHub repository with this code.

### 2. GitHub Secrets

To enable the automated deployment workflow, you must add the following **Secrets** to your GitHub repository settings (`Settings` -> `Secrets and variables` -> `Actions`):

| Secret Name       | Description                                                                 |
| ----------------- | --------------------------------------------------------------------------- |
| `SSH_HOST`        | The public IP address (or hostname) of your Oracle Cloud instance.          |
| `SSH_USERNAME`    | The SSH username (e.g., `ubuntu`).                                          |
| `SSH_PRIVATE_KEY` | Your private SSH key (PEM format) used to access the instance.              |
| `TAILSCALE_IP`    | The Tailscale IP address of your Oracle instance (e.g., `100.x.y.z`).       |
| `PIHOLE_PASSWORD` | (Optional) Password for the Pi-hole Web Interface. Defaults to `admin`.     |

### 3. First Run

Once the secrets are configured, push a commit to the `main` branch. The GitHub Action will:
1.  SSH into your server.
2.  Copy the configuration files to `/lab`.
3.  Create a `.env` file with your `TAILSCALE_IP`.
4.  Run `docker compose up -d`.

### 4. Verification

After deployment, connect to your Tailscale network on your local machine and try accessing:

-   **NPM Admin:** `http://<TAILSCALE_IP>:81` (Default: `admin@example.com` / `changeme`)
-   **Pi-hole:** Since NPM is running on port 80, you will likely need to configure a Proxy Host in NPM to access Pi-hole, OR access it via the internal docker network if you set up port forwarding.
    *   *Initial Setup:* Use NPM to proxy `http://pihole.internal` (or a real domain) to the container hostname `pihole` on port `80`.

To verify DNS:
```bash
dig @<TAILSCALE_IP> google.com
```

## Maintenance

-   **Configuration Changes:** Edit `config/unbound/unbound.conf` locally and push to GitHub. The pipeline will update the file and restart containers.
-   **Updates:** The `docker-compose.yml` uses `latest` tags. Restarting the stack (or re-running the pipeline) will pull new images if available.
