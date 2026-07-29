# 02 — Server `/api/chat` proxy endpoint

Status: ready-for-agent

Parent: [PRD](../PRD.md)
Depends on: 01

## Goal

A stateless proxy route that accepts an OpenAI-shaped chat request from the
phone, prepends the assembled system prompt, forwards to OpenRouter, and returns
the response verbatim. The server holds the provider key and the knowledge doc;
it holds no conversation state.

## Where

- New: `server/lib/api/chat_api.dart`
- New: `server/lib/services/knowledge_service.dart`
- `server/lib/config.dart` — new env vars
- `server/bin/server.dart:33-76` — register the route

## Tasks

- **Config** (`ServerConfig.fromEnvironment`, `server/lib/config.dart`): add
  `openRouterApiKey` (`OPENROUTER_API_KEY`, required), `chatModel`
  (`CHAT_MODEL`, required — the one env var that swaps models), and
  `knowledgeDir` (`KNOWLEDGE_DIR`, default `/data/knowledge`). Follow the
  existing throw-on-missing pattern used for `JACKED_API_KEY`.
- **KnowledgeService**: read `system.md` + `percentages.md` + `capabilities.md`
  from `knowledgeDir` **once at startup** and hold the concatenated string in
  memory. Reading per request would be wasteful and risks a partially-written
  file mid-deploy. Log the character count on boot.
- **System prompt assembly**, in this fixed order (stable prefix first — see
  Notes):
  1. Role and coaching stance — compliant on session-level requests, one
     sentence of doctrine before block-level proposals (PRD decision 13).
  2. Tool-use rules — never state a weight you did not get from a tool result;
     `exercise` must come from the snapshot's vocabulary; `bump_tms` moves all
     four TMs and counts as a cycle bump, `correct_tm` fixes one TM and does not.
  3. The knowledge doc (`system.md`).
  4. `percentages.md`.
  5. `capabilities.md`.
- **Route** `POST /api/chat`. Request body: `{messages: [...], tools: [...]}`
  exactly as the phone built it. Server prepends the system message, injects
  `model` from config, forwards to
  `https://openrouter.ai/api/v1/chat/completions` with
  `Authorization: Bearer $OPENROUTER_API_KEY`, and returns the upstream JSON
  body and status unchanged.
- **Prompt caching**: mark the system message for caching per OpenRouter's
  passthrough for the configured model, and verify a cache hit is actually
  reported on the second request. The 48k prefix is the dominant cost; if it is
  not caching, that is a bug, not a tuning detail.
- Register in `server/bin/server.dart` alongside the existing routes. No auth
  work needed — `authMiddleware` already wraps the whole pipeline
  (`server/bin/server.dart:78-82`) and accepts `Bearer <JACKED_API_KEY>`.
- Bump `serverVersion` (`server/lib/version.dart`).

## Acceptance

- `curl -H "Authorization: Bearer $JACKED_API_KEY" -X POST .../api/chat` with a
  one-message body returns a model reply.
- The same request without the header returns 401 (inherited middleware).
- Second identical request reports a prompt-cache hit in the upstream usage
  fields; log it at boot-time verbosity so it is checkable.
- Changing `CHAT_MODEL` in `prod.env` and restarting switches models with no
  code change.
- `OPENROUTER_API_KEY` appears only in `scripts/prod.env` (gitignored).

## Notes

- Deliberately no spend guard or rate limit (PRD decision 15).
- Do **not** add an SDK dependency — there is no official Anthropic or OpenAI
  Dart SDK, and the OpenAI-compatible shape is plain JSON over `package:http`.
- Server stays stateless: no conversation storage, no session ids. Everything
  the model needs arrives in the request.
- Keep the system prompt byte-identical across requests. Any per-request
  interpolation (timestamps, ids) ahead of the knowledge doc destroys caching.
