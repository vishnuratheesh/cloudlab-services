# Service Access & Configuration Guide

This guide details how to securely access your Pi-hole instance which runs as a dedicated node on your Tailscale network.

## Architecture

We use the "Tailscale Sidecar" pattern.
*   **Pi-hole** runs alongside a dedicated **Tailscale** container.
*   This setup registers Pi-hole as a distinct machine on your Tailscale network (named `pihole`), separate from the server it runs on.
*   It allows Pi-hole to have its own valid HTTPS certificate provided by Tailscale.

## Prerequisites

1.  **Tailscale Auth Key:**
    *   Generate an Auth Key in the [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys).
    *   (Optional but recommended) check "Reusable" if you plan to redeploy often, or "Ephemeral" if testing.
    *   Add this key to your `.env` file on the server:
        ```bash
        TS_AUTHKEY=tskey-auth-xxxxx-yyyyy
        ```

2.  **Deploy:**
    *   Run `docker-compose up -d`.

---

## Enabling HTTPS (Tailscale Serve)

Once the containers are running, the `pihole` machine will appear in your Tailscale dashboard. To enable valid HTTPS and access the web interface:

1.  **Run the Serve Command:**
    Execute this command on your server **once** to configure the Tailscale sidecar to serve HTTPS and proxy it to Pi-hole:

    ```bash
    docker exec ts-pihole tailscale serve https / http://127.0.0.1:80
    ```

    *   *Explanation:* This tells the `ts-pihole` container to listen on port 443 (HTTPS) with a valid certificate and forward all traffic to `http://127.0.0.1:80` (where Pi-hole is listening inside the shared network namespace).

## Accessing Pi-hole

You can now access Pi-hole using its distinct machine name:

*   **URL:** `https://pihole.<tailnet-name>.ts.net/admin`
    *   *Example:* `https://pihole.tailda123.ts.net/admin`
*   **Note:** You do **not** need to accept any security warnings. The certificate is valid and managed automatically by Tailscale.

## Troubleshooting

*   **DNS Resolution:**
    *   The sidecar is configured with `--accept-dns=false`. This ensures it uses Docker's internal DNS to resolve the `unbound` container name.
*   **Blocklists:**
    *   Pi-hole fetches blocklists via the sidecar's network connection. Ensure your server has internet access.
