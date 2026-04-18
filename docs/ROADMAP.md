# AI Lab Roadmap & Ideas

This file serves as a lightweight wiki and memory store for future improvements, configurations, and considerations for the home lab stack.

## Layered Architecture

The stack is broken into logical `docker-compose` layers, found in the `compose/` directory.

1. **Network**: Core DNS routing, Proxy, and Auth.
2. **Data**: PostgreSQL and Vector memory.
3. **AI Core**: Ollama models and unified proxy (LiteLLM).
4. **AI Apps**: Web UIs, search tools, and agent workflows.
5. **Automation**: n8n for stitching systems together.
6. **Management**: Uptime Kuma and Dockge for stack control.

## Recently Added Apps
* **Dockge**: A reactive, web-based management UI for Docker Compose files. It natively interacts with our `compose/` directory.
* **LiteLLM**: Unified endpoint routing and load balancing for local Ollama and external APIs (OpenAI, Gemini).
* **SearxNG**: A privacy-respecting, self-hosted metasearch engine to allow our LLMs to browse the live web via Open WebUI or n8n.
* **Flowise**: An open-source UI visual tool to build customized LLM workflows and agents (e.g., complex RAG).

## Future Considerations / Backlog

### Storage & Observability
- Consider moving from basic log files to **Grafana/Prometheus** if performance monitoring becomes critical.
- Investigate **Zep or Mem0** for dedicated, advanced AI memory if PostgreSQL with `pgvector` becomes a bottleneck for deep contextual chains.

### Networking & Security
- Review if NPM should route to `ts-*` machine Tailscale IPs rather than Docker internal IPs, depending on whether we want pure TLS-termination inside Tailscale or proxy-based termination.
- Fine-tune SearxNG settings to restrict specific engine blocks to improve LLM scraping capabilities.

### Deployment & CI/CD
- Currently, Dockge monitors the `compose/` directory. If you make live edits in Dockge, they are local to the server. Remember to sync them back via GitHub, or use Dockge purely as a reader/restart mechanism since the CI/CD pipeline is the single source of truth.
