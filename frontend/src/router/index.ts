import { createRouter, createWebHistory } from "vue-router";

// One route per view. A new view is added here and nowhere else.
const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: "/",
      name: "home",
      component: () => import("../views/HomeView.vue"),
    },
  ],
});

export default router;
