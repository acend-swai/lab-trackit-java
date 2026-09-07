---
applyTo: "frontend/**"
---

# Frontend instructions

Full detail: `AGENTS.md` (Frontend rules). This file is the path-scoped
summary for Copilot; where the two disagree, `AGENTS.md` wins.

- `<script setup lang="ts">` only, never the options API.
- `src/api/` - one module per resource, exporting typed functions that mirror
  the backend record field for field. All HTTP goes through the shared
  `client` in `src/api/client.ts` - never call `axios` directly, never
  hardcode a host, relative URLs only (the dev server proxies `/api` to
  port 8080).
- `src/views/` - one component per route, named `<Thing>View.vue`, owning all
  three of loading, error and loaded state. A view that only renders the
  happy path is not finished.
- `src/router/index.ts` - the only place a route is registered.
- `src/components/` - reusable pieces, no HTTP calls of their own.
- Verify with `npx vue-tsc -b` (must exit 0) and `npm run build` (must
  succeed) - and say plainly that a green build does not prove the screen
  works; the proof is loading it against the running backend.
- Do not add a dependency to `package.json` without saying so first.
