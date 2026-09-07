import { createApp } from "vue";
import PrimeVue from "primevue/config";
import Aura from "@primevue/themes/aura";
import "primeicons/primeicons.css";

import App from "./App.vue";
import router from "./router";

createApp(App)
  .use(router)
  .use(PrimeVue, { theme: { preset: Aura } })
  .mount("#app");
