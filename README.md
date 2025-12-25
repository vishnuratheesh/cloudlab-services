# Home DNS Stack: Pi-hole + Unbound + Nginx Proxy Manager

This repository contains the configuration for hosting a secure, private DNS and Proxy stack on a cloud instance (e.g., Oracle Cloud Free Tier), utilizing Tailscale for network isolation.

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

### 3. GitHub Secrets

Add the following **Secrets** to your GitHub repository (`Settings` -> `Secrets and variables` -> `Actions`):

| Secret Name       | Description                                                                 |
| ----------------- | --------------------------------------------------------------------------- |
| `TS_AUTHKEY`      | **Reusable, Ephemeral** Tailscale Auth Key tagged with `tag:ci`.            |
| `SSH_HOST`        | The **Tailscale IP address** of your server (e.g., `100.x.y.z`).            |
| `SSH_USERNAME`    | The SSH username (e.g., `sysadmin` or `ubuntu`).                            |
| `SSH_PRIVATE_KEY` | Your private SSH key (PEM format) used to access the instance.              |
| `TAILSCALE_IP`    | The Tailscale IP address of your Oracle instance (e.g., `100.x.y.z`).       |
| `PIHOLE_PASSWORD` | (Optional) Password for the Pi-hole Web Interface. Defaults to `admin`.     |

### 4. Deployment

Push to the `main` branch. The workflow will:
1.  Join the Tailscale network (as `tag:ci`).
2.  Connect to your server via SSH over the private tunnel.
3.  Clean up old config (`rm -rf config docker-compose.yml`) in `/lab/docker/cloudlab` while preserving `data/`.
4.  Deploy the new configuration and restart services.

### 5. Verification

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
