# SHAHM — Evaluation of five external Claude Code tools

**Date:** 2026-11-14 · **Scope:** developer tooling for the SHAHM React + TypeScript Admin and Merchant web prototype (per *SHAHM Claude Code Tools Integration Guide*).
**Status: evaluation only. Nothing was installed, configured, linked, scanned or uploaded.** Each tool needs separate, explicit owner approval before step 1 of its install.

## Baseline (checked read-only)

| Item | Value |
|---|---|
| Claude Code | 2.1.258 |
| Installed Claude Code plugins | none (`claude plugin list`) |
| Project agent rules | `CLAUDE.md` + `.claude/agents` (ECC / claude-code-templates, copied manually) |
| Quality gate | `npm test` (193 business-rule checks) + `npm run build` (tsc + vite) |
| Hosting | Vercel prototype; demo data lives in the browser (localStorage), no backend, no real customer data |

None of the five tools is needed to build, test or deploy SHAHM today. All would sit **outside** `src/` and outside `package.json`; none may become a dependency of the app bundle.

## Summary

| # | Tool | What it is | Licence | Verdict for SHAHM now |
|---|---|---|---|---|
| 1 | Claude Plugins Official | Anthropic's plugin marketplace | Apache-2.0 (each plugin has its own) | **Recommended — 1–2 specific plugins only** |
| 2 | Claude-Mem | Session-memory hooks + local worker + AI summariser | Apache-2.0 | **Not now** (CLAUDE.md + memory already cover it; privacy cost) |
| 3 | Agent-Reach | CLI to read/search X, Reddit, YouTube, web… | MIT | **Skip** (no SHAHM need; copies browser logins) |
| 4 | Strix | Autonomous AI pentester with exploit PoCs (Docker) | Apache-2.0 | **Defer** until there is a backend/staging to test |
| 5 | FreeLLMAPI | Self-hosted router over free-tier LLM APIs | MIT | **Skip** (experimental, replaces Claude's endpoint) |

---

## 1. Claude Plugins Official — `anthropics/claude-plugins-official`

**Purpose.** Anthropic-managed marketplace (`claude-plugins-official`). `/plugins` holds Anthropic's own 43 plugins (checked on every PR); `/external_plugins` holds older third-party ones that are being moved out. Anthropic states it does not control or verify MCP servers/software bundled in third-party plugins.

**Integration.** Inside Claude Code: `/plugin` → Discover, then `/plugin install <name>@claude-plugins-official`. User scope; nothing touches the repo.

**Relevant candidates** (from the current `/plugins` list): `typescript-lsp` (type-aware navigation/diagnostics for TS), `code-review` / `pr-review-toolkit` (review before commits), `frontend-design`, `commit-commands`, `claude-md-management`, `security-guidance`.

| Advantages | Disadvantages / risks |
|---|---|
| First-party, open source, per-user, easy to remove | Each plugin can add hooks, MCP servers or commands; some overlap the ECC agents already present |
| `typescript-lsp` gives real compiler-backed answers on this TS codebase | LSP plugins need a local language server (more processes) |
| Review plugins fit the existing "review before commit" rule | Installing many plugins adds context noise and slower sessions |

**Prerequisites.** Claude Code (present). For `typescript-lsp`: the TypeScript language server.
**Data/network.** First-party plugins run locally; check any plugin's `.mcp.json` for network servers before install.
**Recommendation.** Approve **`typescript-lsp`** first, then optionally **`code-review`**. Do not install the whole catalogue or any `external_plugins` entry.
**Verification.** `claude plugin list`; run a read-only task (e.g. "find all references to `setPublicBroadcast`").
**Rollback.** `/plugin uninstall <name>@claude-plugins-official` (or `claude plugin uninstall …`); no repo changes to revert.

## 2. Claude-Mem — `thedotmack/claude-mem` (v15.18.3)

**Purpose.** Records tool activity during sessions, compresses it into "observations" with an LLM, and injects them into later sessions.

**Integration.** `npx claude-mem install` (interactive) or `/plugin marketplace add thedotmack/claude-mem` → `/plugin install claude-mem`, then restart. Registers **9 hooks** (SessionStart, UserPromptSubmit, Pre/PostToolUse, PostToolUseFailure, Stop, SubagentStop, SessionEnd, Setup) and a **Bun-managed local HTTP worker**.

**Prerequisites.** Node ≥ 20.19 / 22.12 (we have 24), Bun and uv (auto-installed if missing), SQLite (bundled).

**Data and privacy.** Stores in `~/.claude-mem/` (SQLite DB, settings, screenshots). Summaries are produced by **one of**: a hosted claude-mem observer (30-day trial, needs a payment method), your own OpenRouter/Gemini key, or your Anthropic plan. **Anonymous telemetry is on by default** (`npx claude-mem telemetry disable`). Cloud sync to cmem.ai is opt-in. `<private>` tags exclude content, but nothing else is documented.

| Advantages | Disadvantages / risks |
|---|---|
| Cross-session recall without re-reading the repo | Every tool call (file contents, commands, outputs) flows through hooks; with a hosted or third-party provider, SHAHM code leaves the machine |
| Searchable local viewer | Background worker + 9 hooks on every action: overhead and a new failure point |
| | Overlaps what we already have: `CLAUDE.md` + Claude Code's own memory directory |
| | No documented uninstall in the README; auto-installs Bun/uv |

**Recommendation.** **Not now.** If later wanted: Anthropic-plan or local provider only, telemetry off, tested with synthetic data, and treated as historical hints (code + `CLAUDE.md` stay authoritative).
**Rollback.** `/plugin uninstall claude-mem` (or remove the hooks it added to `~/.claude/settings.json`), stop the worker, delete `~/.claude-mem/`. Back up `~/.claude/settings.json` first.

## 3. Agent-Reach — `Panniantong/Agent-Reach`

**Purpose.** One CLI for agents to search/read platforms (default: web, GitHub, YouTube, Bilibili, V2EX; optional: Reddit, LinkedIn, XiaoHongShu…; experimental: X, Facebook, Instagram). Read-only.

**Integration.** The README's primary path is telling the agent to follow `docs/install.md` (agent-driven install via `uv tool install …` + `agent-reach setup`). **Not** the PyPI package of the same name (impostor). Python ≥ 3.10, uv.

**Data and privacy.** For logged-in platforms it **copies that site's login cookies from your Chrome profile** into its own background browser (recommends a secondary account). Fallback readers Jina Reader / Exa and optional Groq/OpenAI transcription receive your URLs/queries. Data in `~/.agent-reach/`.

| Advantages | Disadvantages / risks |
|---|---|
| Reads sources plain web fetch cannot (YouTube transcripts, Reddit…) | No SHAHM task needs these sources; normal web search + vendor docs suffice |
| Read-only by design, MIT | Copies real browser sessions; platform ToS / account-restriction risk |
| | Agent-driven installer executes remote instructions; several third-party upstream tools |

**Recommendation.** **Skip.** Revisit only for a concrete public-research task, with a secondary account and no SHAHM data in queries.
**Rollback.** Its documented uninstall (agent lists and deletes what it installed), `uv tool uninstall agent-reach`, delete `~/.agent-reach/`.

## 4. Strix — `usestrix/strix`

**Purpose.** Autonomous AI penetration tester: recon, exploitation and **working proof-of-concept exploits**, SAST + DAST, against local code, repos, live URLs or OpenAPI files. Results in `strix_runs/<run>`.

**Integration.** CLI via `curl -sSL https://strix.ai/install | bash` (review the script first — guide §6), or `pipx`/`uv` package `strix-agent`. `npx skills add usestrix/strix` adds 9 agent skills but **not** the runtime. Requires **Docker** (sandbox image pulled on first run) and an LLM: `STRIX_LLM` + `LLM_API_KEY` (recommended defaults are third-party GLM models via Vercel AI Gateway/OpenRouter), or local via `LLM_API_BASE`. Config in `~/.strix/cli-config.json`. Hosted Strix Cloud also exists (not proposed).

| Advantages | Disadvantages / risks |
|---|---|
| Validates real findings instead of guessing | SHAHM is a client-only prototype: auth, roles and wallet rules run in the browser **by design** (a demo), so findings would mostly restate known prototype limits |
| Good fit later for the production API (authz, IDOR, wallet invariants) | Active exploitation: must never target `shahm-prototype.vercel.app` (Vercel's infra) or any third party (OSM/Photon) |
| Headless mode for CI | Code is sent to the chosen LLM provider; needs Docker + paid API key |

**Recommendation.** **Defer** until there is a backend + staging environment. If wanted earlier: a **source-only (SAST) run on a local checkout** with a provider the owner approves, no URL targets.
**Rollback.** `pipx/uv tool uninstall strix-agent` (or remove the binary), `docker rmi` the sandbox image, delete `~/.strix/` and `strix_runs/`.

## 5. FreeLLMAPI — `tashfeenahmed/freellmapi`

**Purpose.** Self-hosted router (`localhost:3001`, `/v1` and Anthropic-format `/v1/messages`) that pools **free-tier keys you register with each provider** (Google, Groq, Cerebras, Mistral, OpenRouter…) and fails over between them. Keys AES-256-GCM-encrypted in SQLite. Its own disclaimer: *"personal experimentation and learning, not production"*; you are responsible for each provider's ToS.

**Integration.** Docker or desktop app, then `npx freellmapi setup-claude --url http://localhost:3001 --api-key <key>` (backs up and merges into Claude Code config; `--dry-run` available) — this **redirects Claude Code to non-Claude models**.

| Advantages | Disadvantages / risks |
|---|---|
| Zero inference cost for throwaway experiments | Replaces the model doing SHAHM work with weaker, variable free models (README: "no frontier models", no SLA, quality drops as daily caps hit) |
| Keys encrypted at rest; MIT | SHAHM code goes to many free-tier providers whose terms often allow training on inputs |
| | Changes Claude Code's endpoint — breaks tool use/quality if misconfigured; one more server to run |

**Recommendation.** **Skip** for SHAHM. Only ever on an isolated profile, never on this project.
**Rollback.** Restore the backed-up Claude Code settings (run `setup-claude --dry-run` first to see the diff), `docker compose down -v` or uninstall the app, delete its data directory (`%APPDATA%\FreeLLMAPI\`).

---

## Proposed order (each step needs its own approval)

1. **`typescript-lsp@claude-plugins-official`** — install, verify with a read-only query, report.
2. Optionally **`code-review@claude-plugins-official`**.
3. Strix — only when a SHAHM backend/staging exists; source-only first.
4. Claude-Mem, Agent-Reach, FreeLLMAPI — not recommended for this project.

Re-check each repository's README and releases immediately before any approved install; these projects change quickly.
