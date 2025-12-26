# Service Access & Configuration Guide

This guide details how to securely access your internal services (Pi-hole and Nginx Proxy Manager) using friendly subdomains (e.g., `pihole.cloudlab.tailnet.ts.net`) over your Tailscale private network.

## Architecture

We utilize a "DNS + Reverse Proxy" strategy to map friendly names to Docker containers without exposing ports publicly.

1.  **DNS (Pi-hole):** Resolves `*.your-machine.tailnet.ts.net` to your server's Tailscale IP.
2.  **Proxy (Nginx Proxy Manager):** Listens on the Tailscale IP (ports 80/443), reads the requested hostname, and forwards traffic to the correct Docker container name (e.g., `pihole`, `npm`) on the internal private network.

## Prerequisites

*   The server is running (`docker-compose up -d`).
*   Your client device is connected to the same Tailscale network.
*   You know your server's Tailscale Machine Name and Domain (e.g., `cloudlab.anoa-stargazer.ts.net`). We will refer to this as `<tailscale-dns>`.

---

## Step 1: SSL Certificates

Because we are using subdomains of `ts.net` (which we do not own), we cannot easily generate valid Let's Encrypt certificates for arbitrary subdomains like `pihole.<tailscale-dns>`.

Instead, we will use a **Self-Signed Wildcard Certificate**. This will cause your browser to show a "Not Secure" warning initially, but the connection is encrypted.

1.  **Generate the Certificate:**
    Run the following command on your server (or any machine with OpenSSL) to generate a certificate valid for all subdomains:

    ```bash
    # Replace <tailscale-dns> with your full Tailscale machine name (e.g. cloudlab.anoa-stargazer.ts.net)
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout selfsigned.key \
      -out selfsigned.crt \
      -subj "/CN=*.<tailscale-dns>"
    ```

2.  **Upload to Nginx Proxy Manager (NPM):**
    *   Log in to NPM (usually at `http://<tailscale-ip>:81`).
    *   Go to **SSL Certificates** > **Add SSL Certificate** > **Custom**.
    *   **Name:** `Self-Signed Wildcard`
    *   **Certificate Key:** Upload `selfsigned.key`.
    *   **Certificate:** Upload `selfsigned.crt`.
    *   Click **Save**.

---

## Step 2: Configure Local DNS (Pi-hole)

We need to tell your network where these names live. Since Tailscale MagicDNS only resolves the machine name, we use Pi-hole to resolve the subdomains.

1.  Log in to Pi-hole (usually `http://<tailscale-ip>:53/admin` or similar).
2.  Navigate to **Local DNS** > **DNS Records**.
3.  Add the following records (replace `<tailscale-dns>` with your full machine domain):

| Domain | IP Address |
| :--- | :--- |
| `pihole.<tailscale-dns>` | `<Your-Tailscale-IP>` |
| `npm.<tailscale-dns>` | `<Your-Tailscale-IP>` |

*(Note: The IP Address is your server's 100.x.y.z Tailscale IP).*

---

## Step 3: Configure Reverse Proxy (NPM)

Now we tell NPM how to route requests for those names to the correct containers.

1.  Log in to NPM.
2.  Navigate to **Hosts** > **Proxy Hosts** > **Add Proxy Host**.

### For Pi-hole
*   **Domain Names:** `pihole.<tailscale-dns>`
*   **Scheme:** `http`
*   **Forward Hostname / IP:** `pihole`
    *   *We use the Docker service name, which is more robust than a static IP.*
*   **Forward Port:** `80`
*   **SSL Tab:** Select `Self-Signed Wildcard`. Force SSL: On.

### For NPM Admin
*   **Domain Names:** `npm.<tailscale-dns>`
*   **Scheme:** `http`
*   **Forward Hostname / IP:** `npm`
*   **Forward Port:** `81`
    *   *Note: NPM Admin runs on port 81 inside the container.*
*   **SSL Tab:** Select `Self-Signed Wildcard`. Force SSL: On.

---

## Accessing Services

You can now access your services securely from any device on your Tailscale network:

*   **Pi-hole:** `https://pihole.<tailscale-dns>/admin`
*   **NPM:** `https://npm.<tailscale-dns>`

*(Accept the browser security warning regarding the self-signed certificate)*.
