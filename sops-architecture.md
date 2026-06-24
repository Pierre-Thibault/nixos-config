# Secret Management Architecture with sops-nix

```mermaid
flowchart LR
    subgraph tools["AI Coding Tools\n(no API keys stored)"]
        cc[Claude Code]
        oc[OpenCode]
        ai[Aider]
    end

    subgraph proxy["Local Caddy Proxy\n(API key injection)"]
        caddy[Caddy]
    end

    subgraph external["External AI Services"]
        openai[OpenAI]
        groq[Groq]
        xai[xAI]
        together[Together AI]
        hf[Hugging Face]
    end

    cc -->|"HTTP · no key"| caddy
    oc -->|"HTTP · no key"| caddy
    ai -->|"HTTP · no key"| caddy

    caddy -->|"injects API key"| openai
    caddy -->|"injects API key"| groq
    caddy -->|"injects API key"| xai
    caddy -->|"injects API key"| together
    caddy -->|"injects API key"| hf

    subgraph sops["Secret Management — sops-nix (NixOS)"]
        direction TB
        encrypted["🔒 Encrypted secrets\ngit repository\n(age encryption)"]
        activation["NixOS activation\nat boot"]
        ram["/run/secrets/\nRAM tmpfs\nnever written to disk"]
        template["/run/secrets/rendered/\napi-proxy.env"]

        encrypted -->|"host SSH key\ndecrypts at boot"| activation
        activation --> ram
        ram --> template
    end

    template -->|"systemd EnvironmentFile"| caddy

    subgraph other["Other Secret Consumers"]
        geoclue["geoclue\ngeo-location API key"]
        scripts["User scripts\nagenda / agenda-mcp\niCloud password"]
    end

    ram -->|"rendered template"| geoclue
    ram -->|"secret file"| scripts
```

**Key properties:**
- AI tools communicate with a **local proxy** — no API keys in tool configuration
- Secrets are **encrypted at rest** in the git repository (age encryption via sops)
- At boot, NixOS decrypts secrets into a **RAM-only tmpfs** (`/run/secrets/`) — never touches disk
- Caddy reads keys via **systemd `EnvironmentFile`** — keys are never exposed through the Caddy admin API
