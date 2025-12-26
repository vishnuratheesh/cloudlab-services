# Firewall Configuration & Security Guide

This guide details how to securely expose your Pi-hole DNS server (Port 53) to your specific remote location (e.g., your home) while blocking the rest of the internet.

## ⚠️ Critical Security Warning

Exposing Port 53 (DNS) to the entire internet (`0.0.0.0/0`) creates an **Open Resolver**.
*   Hackers will use your server to launch DDoS attacks against others (DNS Amplification Attacks).
*   Your cloud provider may suspend your account for abuse.
*   **You MUST restrict access to your specific IP address.**

---

## Part 1: Cloud Provider Firewall (Security Groups)

Most cloud providers (AWS, Oracle, Google Cloud, DigitalOcean, etc.) have an external firewall layer often called **Security Groups**, **Security Lists**, or **Firewalls**.

1.  **Find your Home IP:**
    *   From your home network, visit [whatismyip.com](https://www.whatismyip.com/) or run `curl ifconfig.me` in a terminal.
    *   Let's assume your IP is `203.0.113.45`.

2.  **Configure the Rule:**
    *   Log in to your Cloud Console.
    *   Navigate to the Networking or Firewall section for your instance.
    *   Add a new **Ingress** (Inbound) rule:
        *   **Protocol:** UDP (and TCP if desired).
        *   **Port Range:** `53`.
        *   **Source / Source CIDR:** Enter your Home IP with `/32` at the end (e.g., `203.0.113.45/32`).
    *   *Note:* The `/32` means "only this exact IP address".

---

## Part 2: OS Level Firewall (Linux)

Even if the cloud firewall allows traffic, the Linux operating system itself might block it.

### Using UFW (Uncomplicated Firewall)
Common on Ubuntu/Debian.

```bash
# Allow DNS from your specific Home IP
sudo ufw allow from 203.0.113.45 to any port 53 proto udp
sudo ufw allow from 203.0.113.45 to any port 53 proto tcp

# Reload to apply
sudo ufw reload
```

### Using IPtables (Standard Linux)
Common on Oracle Linux, CentOS, or minimal images.

```bash
# Insert rule at the top of the INPUT chain
sudo iptables -I INPUT 1 -p udp --dport 53 -s 203.0.113.45 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 53 -s 203.0.113.45 -j ACCEPT

# Save the rules (Persistent)
# Command varies by distro. Common examples:
sudo netfilter-persistent save
# OR
sudo service iptables save
```

### Note for Oracle Cloud Users
Oracle images often use `iptables` rules that are strict by default. You may need to explicitly open ports in the OS even if the Security List allows it. Check `/etc/iptables/rules.v4` if your changes don't persist.
