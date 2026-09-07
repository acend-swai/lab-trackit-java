<script setup lang="ts">
import { onMounted, ref } from "vue";
import { createTask, listTasks, type Task } from "../api/tasks";

const tasks = ref<Task[]>([]);
const title = ref("");
const project = ref("trackit");
const loading = ref(false);
const error = ref<string | null>(null);

async function load() {
  loading.value = true;
  error.value = null;
  try {
    tasks.value = await listTasks();
  } catch {
    error.value = "Could not reach the backend on /api/v1/tasks.";
  } finally {
    loading.value = false;
  }
}

async function submit() {
  if (!title.value.trim()) {
    error.value = "A task needs a title.";
    return;
  }
  error.value = null;
  try {
    await createTask({ title: title.value, project: project.value });
    title.value = "";
    await load();
  } catch {
    error.value = "The task could not be created.";
  }
}

onMounted(load);
</script>

<template>
  <section>
    <form class="new-task" @submit.prevent="submit">
      <input v-model="title" placeholder="What needs doing?" aria-label="Task title" />
      <input v-model="project" placeholder="Project" aria-label="Project" />
      <button type="submit">Add task</button>
    </form>

    <p v-if="error" class="error">{{ error }}</p>
    <p v-else-if="loading">Loading tasks...</p>
    <p v-else-if="tasks.length === 0">No tasks yet. Add the first one above.</p>

    <ul v-else class="task-list">
      <li v-for="task in tasks" :key="task.id">
        <span class="status" :data-status="task.status">{{ task.status }}</span>
        <span class="title">{{ task.title }}</span>
        <span class="project">{{ task.project }}</span>
      </li>
    </ul>
  </section>
</template>

<style scoped>
.new-task {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}
.new-task input {
  padding: 0.5rem 0.75rem;
  border: 1px solid #c3ced2;
  border-radius: 4px;
  font: inherit;
}
.new-task button {
  padding: 0.5rem 1rem;
  border: 0;
  border-radius: 4px;
  background: #0f7c86;
  color: #ffffff;
  font: inherit;
  cursor: pointer;
}
.task-list {
  list-style: none;
  margin: 0;
  padding: 0;
}
.task-list li {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.6rem 0.75rem;
  background: #ffffff;
  border: 1px solid #e1e8ea;
  border-radius: 4px;
  margin-bottom: 0.4rem;
}
.status {
  font-size: 0.7rem;
  letter-spacing: 0.06em;
  padding: 0.15rem 0.45rem;
  border-radius: 3px;
  background: #e6f2f3;
  color: #0f7c86;
}
.status[data-status="DONE"] {
  background: #e8efe6;
  color: #4a7c3f;
}
.title {
  flex: 1;
}
.project {
  color: #6b7a80;
  font-size: 0.85rem;
}
.error {
  color: #a3302b;
}
</style>
