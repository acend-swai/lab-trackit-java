package ch.acend.trackit.service;

import ch.acend.trackit.domain.Task;
import ch.acend.trackit.domain.TaskEntity;
import ch.acend.trackit.domain.TaskStatus;
import ch.acend.trackit.dto.CreateTaskRequest;
import ch.acend.trackit.repository.TaskRepository;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Business logic for tasks. Tasks are stored in PostgreSQL since lab 1.2. */
@Service
public class TaskService {

    private final TaskRepository taskRepository;

    public TaskService(TaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }

    @Transactional
    public Task create(CreateTaskRequest request) {
        TaskEntity saved = taskRepository.save(
                new TaskEntity(request.title(), request.project(), TaskStatus.OPEN));
        return saved.toDomain();
    }

    @Transactional(readOnly = true)
    public List<Task> findAll() {
        return taskRepository.findAll().stream().map(TaskEntity::toDomain).toList();
    }

    @Transactional(readOnly = true)
    public Optional<Task> findById(long id) {
        return taskRepository.findById(id).map(TaskEntity::toDomain);
    }
}
