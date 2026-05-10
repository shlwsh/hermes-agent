# OpenClaw -> Hermes Migration Report

- Timestamp: 20260510T142702
- Mode: execute
- Source: `/home/smz/.openclaw`
- Target: `/home/smz/.hermes`

## Summary

- migrated: 9
- archived: 14
- skipped: 24
- conflict: 1
- error: 0

## What Was Not Fully Brought Over

- `/home/smz/.openclaw/workspace/AGENTS.md` -> `(n/a)`: No workspace target was provided
- `(n/a)` -> `/home/smz/.hermes/memories/MEMORY.md`: Source file not found
- `/home/smz/.openclaw/openclaw.json` -> `/home/smz/.hermes/.env`: No Hermes-compatible messaging settings found
- `/home/smz/.openclaw/openclaw.json` -> `/home/smz/.hermes/.env`: No allowlisted Hermes-compatible secrets found
- `/home/smz/.openclaw/openclaw.json` -> `/home/smz/.hermes/.env`: No Discord settings found
- `/home/smz/.openclaw/openclaw.json` -> `/home/smz/.hermes/.env`: No Slack settings found
- `/home/smz/.openclaw/openclaw.json` -> `/home/smz/.hermes/.env`: No WhatsApp settings found
- `/home/smz/.openclaw/openclaw.json` -> `/home/smz/.hermes/.env`: No Signal settings found
- `/home/smz/.openclaw/openclaw.json` -> `/home/smz/.hermes/.env`: No provider API keys found
- `/home/smz/.openclaw/openclaw.json` -> `/home/smz/.hermes/config.yaml`: No TTS configuration found in OpenClaw config
- `(n/a)` -> `/home/smz/.hermes/config.yaml`: No OpenClaw exec approvals file found
- `(n/a)` -> `/home/smz/.hermes/skills/openclaw-imports`: No shared OpenClaw skills directories found
- `(n/a)` -> `/home/smz/.hermes/tts`: Source directory not found
- `/home/smz/.openclaw/openclaw.json` -> `(n/a)`: Selected Hermes-compatible values were extracted; raw OpenClaw config was not copied.
- `/home/smz/.openclaw/memory/main.sqlite` -> `(n/a)`: Contains secrets, binary state, or product-specific runtime data
- `/home/smz/.openclaw/devices` -> `(n/a)`: Contains secrets, binary state, or product-specific runtime data
- `/home/smz/.openclaw/identity` -> `(n/a)`: Contains secrets, binary state, or product-specific runtime data
- `(n/a)` -> `(n/a)`: No MCP servers found in OpenClaw config
- `(n/a)` -> `(n/a)`: No browser configuration found
- `(n/a)` -> `(n/a)`: No approvals configuration found
- `(n/a)` -> `(n/a)`: No memory backend configuration found
- `(n/a)` -> `(n/a)`: No skills registry configuration found
- `(n/a)` -> `(n/a)`: No UI/identity configuration found
- `(n/a)` -> `(n/a)`: No logging/diagnostics configuration found
- `/home/smz/.openclaw/workspace/SOUL.md` -> `/home/smz/.hermes/SOUL.md`: Target exists and overwrite is disabled
