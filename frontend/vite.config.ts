import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

// The dev server proxies /api to the Spring Boot backend, so the browser talks to
// one origin and there is no CORS configuration to get wrong.
export default defineConfig({
  plugins: [vue()],
  server: {
    host: "0.0.0.0",
    port: 5173,
    proxy: {
      "/api": {
        target: "http://localhost:8080",
        changeOrigin: true,
      },
    },
  },
});
