# Ledgerly API — Cloudflare Worker Backend Design

**Date:** 2026-05-11
**Status:** Draft

## Overview

A Cloudflare Worker backend service for Ledgerly that acts as a proxy/gateway for fetching data from 3rd party APIs. Uses Workers KV for TTL-based response caching. Starting with a placeholder endpoint (`https://ifconfig.me`), with Ankr blockchain API planned for Phase 2.

## Tech Stack

| Layer | Choice |
|-------|--------|
| Runtime | Cloudflare Workers |
| Framework | Hono (TypeScript) |
| Cache | Workers KV |
| Testing | Vitest + `@cloudflare/vitest-pool-workers` |
| Deployment | Wrangler CLI |

## Project Structure

```
ledgerly-api/
├── src/
│   ├── index.ts              # Hono app entry, mounts routes
│   ├── routes/
│   │   └── proxy.ts          # POST /proxy/:endpoint route
│   └── services/
│       ├── cache.ts          # KV read/write with TTL logic
│       └── proxy.ts          # Upstream fetch wrapper
├── test/
│   ├── routes/
│   │   └── proxy.test.ts
│   └── services/
│       └── cache.test.ts
├── wrangler.toml
├── package.json
├── tsconfig.json
└── vitest.config.ts
```

## API Design

### Endpoint Allowlist

To prevent open proxy abuse, the worker maintains an allowlist of permitted upstream endpoints:

```typescript
const ALLOWED_ENDPOINTS: Record<string, string> = {
  "ifconfig.me": "https://ifconfig.me",
  // "ankr": "https://rpc.ankr.com",  // Phase 2
};
```

The `:endpoint` path parameter is resolved against this map. Unknown keys return `404 Not Found`. Adding new upstream APIs is a config change, not a code change.

### Routes

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Returns `{ status: "ok" }`, no caching |
| `POST` | `/proxy/:endpoint` | Proxies request body to the allowed upstream URL, caches response in KV. The worker always POSTs to upstream regardless of client method. Empty body is valid (cache key = SHA-256 of empty string). |

### Cache Key Strategy

Key = `proxy:{endpoint}:{bodyHash}` where `bodyHash` is SHA-256 of the request body. Identical POST bodies share cache entries; different bodies get separate entries.

**KV size constraint:** Workers KV values are limited to 25 MiB. Responses exceeding this limit are not cached; the upstream response is returned directly with a warning logged.

### Request/Response Flow

```
Client POST /proxy/ifconfig.me
  → Hono route handler
  → Validate :endpoint against ALLOWED_ENDPOINTS
  → 404 if not found
  → Cache service: check KV for key
  → HIT: return cached response (X-Cache: HIT header)
  → MISS: fetch upstream → store in KV with TTL → return response (X-Cache: MISS)
```

### Headers

- `X-Cache: HIT|MISS` — indicates whether response was served from cache
- Upstream headers are forwarded as-is, except the following hop-by-hop headers which are stripped:
  - `Connection`
  - `Keep-Alive`
  - `Transfer-Encoding`
  - `TE`
  - `Trailer`
  - `Upgrade`
  - `Proxy-Authorization`
  - `Proxy-Authenticate`

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DEFAULT_TTL` | `60` | Default cache TTL in seconds |

### KV Namespaces

- Binding: `CACHE_KV`
- Separate namespaces for `dev`, `staging`, `prod` via `[env]` blocks in `wrangler.toml`

## Error Handling

| Scenario | Response |
|----------|----------|
| Unknown `:endpoint` (not in allowlist) | `404 Not Found` with `{ error: "Endpoint not allowed" }` |
| Upstream timeout (10s) | `504 Gateway Timeout` with error body |
| Upstream non-2xx | Forward status code + body, no caching |
| Response exceeds 25 MiB KV limit | Return upstream response without caching, log warning |
| KV read failure | Fall through to upstream (graceful degradation) |
| KV write failure | Log warning, return upstream response without caching |

## Testing Strategy

### Unit Tests (`test/services/cache.test.ts`)

- TTL calculation and expiry
- Cache key generation (deterministic for same input)
- Hit/miss logic

### Integration Tests (`test/routes/proxy.test.ts`)

- Full request → cache → response flow
- Cache hit returns `X-Cache: HIT`
- Cache miss fetches upstream, returns `X-Cache: MISS`
- Upstream error forwarded correctly
- TTL expiry triggers fresh fetch

### Mocking

- Upstream HTTP calls are mocked in all tests (no real network requests)
- KV uses miniflare's in-memory implementation via `@cloudflare/vitest-pool-workers`

## Security

- **Endpoint allowlist** prevents open proxy abuse — only explicitly listed upstreams are reachable
- **Worker-level authentication** (e.g., API keys, JWT) is out of scope for Phase 1. The allowlist provides sufficient protection for the initial setup. Auth will be added when the Flutter client needs to call the worker in production.

## Future Extensions

- Add route-specific TTL configuration
- Add Ankr API route with API key management via secrets
- Add request rate limiting
- Add CORS configuration for Flutter web builds
