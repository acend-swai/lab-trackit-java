---
name: add-view
description: Use when adding a screen to the TrackIt frontend, or when the user says "add a view", "add a page", "show the tasks in the browser", "build the task board", or "wire the frontend to the API". Applies the TrackIt frontend house pattern - typed API module, one view per route, loading and error state, route registered in router/index.ts.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Add a view, TrackIt house pattern

Add one screen that reads and writes one resource through the backend API.

## Before you start

Read `AGENTS.md` and `docs/architecture.md`. The frontend rules there win over
anything in this file. Read `src/api/client.ts` before writing an API module - the
axios instance and its base URL already exist.

Adding a dependency needs the user's agreement first. The scaffold already carries
Vue, the router, axios and PrimeVue.

## Steps

1. **API module.** Create `src/api/<resource>.ts`. Export the TypeScript types that
   mirror the backend record field for field, and one async function per endpoint.
   Import the shared `client` - never call `axios` directly, never hardcode a host.

2. **View.** Create `src/views/<Thing>View.vue` with `<script setup lang="ts">`.
   It owns three states and renders all three: loading, error, and empty. A view that
   only renders the happy path is not finished.

3. **Route.** Register the view in `src/router/index.ts`. That file is the only place
   a route is declared.

4. **Verify.** Run, from `frontend/`:
   - `npx vue-tsc -b` - must exit 0, no type errors
   - `npm run build` - must succeed

   Then say plainly that a green build does not prove the screen works, and that the
   proof is loading it in the browser against the running backend.

## Rules

- `<script setup lang="ts">` only, never the options API.
- Types mirror the backend record. If a field is `long` in Java it is `number` here.
- The API module is the only place that speaks HTTP. Components never fetch.
- Relative URLs only. The Vite dev server proxies `/api` to port 8080.
- One view per run.

## Out of scope

- Editing anything under `backend/`.
- Authentication, routing guards, state management libraries.
- Installing dependencies without asking.
