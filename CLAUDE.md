# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hermes Agent is a self-improving AI agent by Nous Research. It runs as an interactive CLI (`hermes`), a long-running messaging gateway (`hermes gateway`), or a programmatic library (`run_agent.py`). It integrates with Telegram, Discord, Slack, Feishu, WhatsApp, Signal, and other platforms, and supports any OpenAI-compatible LLM provider.

## Common Commands

```bash
# Development setup
uv venv venv --python 3.11 && source venv/bin/activate
uv pip install -e ".[all,dev]"

# Tests (integration tests skipped by default via pytest addopts)
python -m pytest tests/ -q              # full suite
python -m pytest tests/gateway/ -q       # gateway tests only
python -m pytest tests/tools/ -q         # tool tests only
python -m pytest tests/test_model_tools.py::test_name -q  # single test

# Running
hermes              # CLI TUI
hermes gateway run  # messaging gateway (foreground)
hermes gateway start # messaging gateway (background service)
hermes setup        # first-run wizard
hermes doctor       # environment diagnostics

# Entry points (installed via pyproject.toml)
hermes        → hermes_cli.main:main
hermes-agent  → run_agent:main
hermes-acp    → acp_adapter.entry:main
```

## Architecture

### Three Entry Points

```
hermes (CLI shim)
  └─ hermes_cli/main.py
       ├─ cli.py + run_agent.py      → interactive TUI (prompt_toolkit)
       ├─ hermes gateway              → gateway/run.py / GatewayRunner (async, long-lived)
       └─ hermes {setup,model,tools,...} → hermes_cli/{setup,models,tools_config,...}.py
```

The gateway and CLI TUI share the same `AIAgent` class but run in completely different modes. The gateway is async and multi-user; the CLI is synchronous and single-user.

### AIAgent (run_agent.py)

The core loop in `run_conversation()`: calls LLM → if `tool_calls`, executes them and loops → if text, returns. Messages use OpenAI format. Reasoning content is stored in `assistant_msg["reasoning"]`.

### Tool Registry Pattern (tools/)

Every tool file calls `registry.register()` at import time. `model_tools.py` imports all tool modules to trigger discovery, then exposes `get_tool_definitions()` and `handle_function_call()`. No central list to maintain.

**Adding a tool (3 files):**
1. `tools/your_tool.py` — self-register with `registry.register()`
2. `model_tools.py` — add import to `_discover_tools()` `_modules` list
3. `toolsets.py` — add to `_HERMES_CORE_TOOLS` or a new toolset

### Gateway Message Flow

```
Platform adapter → GatewayRunner._handle_message()
  → session_store.get_or_create_session()
  → AIAgent (per-session, cached for prompt caching continuity)
    → prompt_builder.build_system_prompt()
    → LLM call loop (run_conversation)
  → adapter.send() → platform delivery
```

`BasePlatformAdapter` defines the uniform interface for all 15+ platform adapters. Each adapter wraps its own SDK (Telegram Bot API, discord.py, lark-oapi, etc.).

### Platform Adapter Pattern (gateway/platforms/)

To add a new platform: create `gateway/platforms/{platform}.py` inheriting `BasePlatformAdapter`, register in `gateway/run.py`'s `_create_adapter()`, implement `connect()`, `disconnect()`, `send()`, `handle_update()`. See `gateway/platforms/ADDING_A_PLATFORM.md` for details.

### Hook System (gateway/hooks.py)

Event-driven extensibility. `HookRegistry.discover_and_load()` scans `~/.hermes/hooks/` for directories containing `HOOK.yaml` + `handler.py`. Events include `gateway:startup`, `session:start/end/reset`, `agent:start/step/end`, `command:*` (wildcard). Built-in hooks (like `boot-md`) are always active.

### Configuration Loading Chain

```
~/.hermes/config.yaml     ← primary config (YAML, user-editable)
    ↓ (hermes_cli/config.py loads, bridges keys → os.environ)
~/.hermes/.env           ← secrets + platform credentials (hermes_cli/env_loader.py)
    ↓ (highest priority)
shell environment         ← lowest priority
```

`config.yaml` is authoritative for most settings and gets bridged into `os.environ` at startup. Platform credentials (Telegram token, Feishu app ID, etc.) come from `.env`.

### Session Management

Primary: SQLite via `hermes_state.SessionDB`. Fallback: JSONL in `~/.hermes/sessions/`. Session key format: `agent:main:{platform}:{chat_type}:{chat_id}[:thread_id][:user_id]`. AIAgent instances are cached per session in the gateway to preserve Anthropic prompt caching continuity — without caching, each message rebuilds the system prompt and breaks the cache prefix.

### Concurrency Safety

Session-scoped state uses `contextvars.ContextVar` (via `gateway/session_context.py`), NOT `os.environ`. Each async task gets its own copy — prevents cross-message contamination in concurrent gateway flows.

## Key Policies

### Language and Documentation
- All reasoning and interactions: **Chinese**.
- All generated documentation: write to **`docs-zh/`** directory.

### Profile Safety (HERMES_HOME)
All state paths must use `get_hermes_home()` from `hermes_constants`. Use `display_hermes_home()` for user-facing messages. Never hardcode `~/.hermes` or `Path.home() / ".hermes"` — this breaks multi-profile isolation.

```python
# GOOD
from hermes_constants import get_hermes_home
path = get_hermes_home() / "sessions"

# BAD — breaks profiles
path = Path.home() / ".hermes" / "sessions"
```

### Prompt Caching Integrity
The ONLY time context is altered mid-conversation is during context compression. Do NOT implement changes that alter past context, change toolsets, or reload memories mid-conversation.

### Known Pitfalls
- **No `simple_term_menu` in tmux/iTerm2** — rendering bugs (ghosting on scroll). Use `curses` (stdlib) instead.
- **No `\033[K` (ANSI erase-to-EOL)** in spinner/display code — leaks as literal text under `prompt_toolkit`. Use space-padding.
- **Tests must not write to `~/.hermes/`** — `_isolate_hermes_home` fixture in `tests/conftest.py` redirects to a temp dir.
- **No hardcoded cross-tool references in schema descriptions** — referenced tools may be disabled/unavailable. Use dynamic injection in `get_tool_definitions()` instead.

## Adding a Slash Command

1. Add `CommandDef` to `COMMAND_REGISTRY` in `hermes_cli/commands.py`
2. Add handler in `HermesCLI.process_command()` in `cli.py`
3. If available in the gateway, add handler in `gateway/run.py`

Adding an alias to an existing command only requires adding it to the `aliases` tuple — dispatch, help text, Telegram menu, Slack mapping, and autocomplete all update automatically.

## Config System

- **config.yaml options**: add to `DEFAULT_CONFIG` in `hermes_cli/config.py`, bump `_config_version`
- **.env variables**: add to `OPTIONAL_ENV_VARS` in `hermes_cli/config.py` with metadata (description, prompt, url, category)
- **Three separate loaders**: `load_cli_config()` (cli.py), `load_config()` (hermes_cli/config.py), direct YAML load (gateway/run.py)

## Further Reading

- `AGENTS.md` — AI developer guide with full policies
- `CONTRIBUTING.md` — contributor setup and commit conventions
- `website/docs/user-guide/messaging/feishu.md` — Feishu platform deep-dive
- `docs-zh/feishu-config-guide.md` — 飞书配置与路径加载指南
- `gateway/platforms/ADDING_A_PLATFORM.md` — how to add a new platform adapter
