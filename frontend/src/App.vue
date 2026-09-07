<script setup lang="ts">
// The shell. Every view is rendered through the router outlet below.
</script>

<template>
  <header class="shell-header">
    <h1>TrackIt</h1>
  </header>
  <main class="shell-main">
    <RouterView />
  </main>
</template>

<style>
body {
  margin: 0;
  font-family: system-ui, sans-serif;
  color: #1f2933;
  background: #f7f9fa;
}
.shell-header {
  padding: 1rem 1.5rem;
  border-bottom: 1px solid #d8e0e3;
  background: #ffffff;
}
.shell-header h1 {
  margin: 0;
  font-size: 1.25rem;
  letter-spacing: 0.02em;
}
.shell-main {
  padding: 1.5rem;
  max-width: 60rem;
}
</style>
