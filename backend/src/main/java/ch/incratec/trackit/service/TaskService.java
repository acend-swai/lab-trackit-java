package ch.incratec.trackit.service;

import ch.incratec.trackit.domain.Task;
import ch.incratec.trackit.domain.TaskStatus;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicLong;
import org.springframework.stereotype.Service;

/**
 * Business logic for tasks. Knows nothing about HTTP. Tasks live in memory until
 * persistence arrives in M2.
 */
@Service
public class TaskService {

    private final List<Task> tasks = new CopyOnWriteArrayList<>();
    private final AtomicLong nextId = new AtomicLong(1);

    /**
     * Creates a task in the OPEN state and assigns it the next id.
     */
    public Task create(String title, String project) {
        Task task = new Task(nextId.getAndIncrement(), title, project, TaskStatus.OPEN);
        tasks.add(task);
        return task;
    }

    /**
     * All tasks, in the order they were created.
     */
    public List<Task> findAll() {
        return List.copyOf(tasks);
    }
}
