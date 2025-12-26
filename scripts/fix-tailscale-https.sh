#!/bin/bash
set -e

echo "Enabling HTTPS for Pi-hole via Tailscale Serve..."

# Enable Tailscale Serve to proxy HTTPS (443) to internal HTTP (80)
# We assume the user wants the root path '/' to proxy to the Pi-hole web interface.
# Pi-hole web interface is usually at /, but sends a redirect to /admin/
# 'docker exec' runs the command inside the ts-pihole container.

docker exec ts-pihole tailscale serve https / http://127.0.0.1:80

echo "Configuration applied. Checking status..."
docker exec ts-pihole tailscale serve status

echo ""
echo "Note: If you see 'Status: Serving', you can access Pi-hole at https://<your-machine-name>.<your-tailnet>.ts.net/admin/"
