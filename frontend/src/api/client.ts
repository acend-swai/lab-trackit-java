import axios from "axios";

// One axios instance for the whole app. The Vite dev server proxies /api to the
// backend on port 8080, so the base URL stays relative and works unchanged when the
// frontend is served from the backend later.
export const client = axios.create({
  baseURL: "/api/v1",
  headers: { "Content-Type": "application/json" },
});
