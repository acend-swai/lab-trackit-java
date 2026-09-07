package ch.acend.trackit.service;

import ch.acend.trackit.domain.Task;
import ch.acend.trackit.domain.TaskStatus;
import ch.acend.trackit.dto.CreateTaskRequest;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicLong;
import org.springframework.stereotype.Service;

/** Business logic for tasks. Holds them in memory until M2 adds persistence. */
@Service
public class TaskService {

    private final List<Task> tasks = new CopyOnWriteArrayList<>();
    private final AtomicLong nextId = new AtomicLong(1);

    public Task create(CreateTaskRequest request) {
        Task task = new Task(
                nextId.getAndIncrement(),
                request.title(),
                request.project(),
                TaskStatus.OPEN);
        tasks.add(task);
        return task;
    }

    public List<Task> findAll() {
        return List.copyOf(tasks);
    }
}
