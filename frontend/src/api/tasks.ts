import { client } from "./client";

// Mirrors ch.acend.trackit.domain.Task field for field.
export type TaskStatus = "OPEN" | "DONE";

export interface Task {
  id: number;
  title: string;
  project: string;
  status: TaskStatus;
}

export interface CreateTaskRequest {
  title: string;
  project: string;
}

export async function listTasks(): Promise<Task[]> {
  const response = await client.get<Task[]>("/tasks");
  return response.data;
}

export async function createTask(request: CreateTaskRequest): Promise<Task> {
  const response = await client.post<Task>("/tasks", request);
  return response.data;
}
