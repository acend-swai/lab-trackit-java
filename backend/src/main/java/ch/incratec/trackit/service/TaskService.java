package ch.incratec.trackit.service;

import ch.incratec.trackit.domain.Task;
import ch.incratec.trackit.domain.TaskStatus;
import ch.incratec.trackit.dto.CreateTaskRequest;
import java.util.List;
import java.util.Optional;
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

    public Optional<Task> findById(long id) {
        return tasks.stream().filter(task -> task.id() == id).findFirst();
    }
}
