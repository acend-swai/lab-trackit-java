package ch.incratec.trackit.domain;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * The stored shape of a task. Deliberately a separate class from the {@link Task}
 * record: the record is the API shape and must not change when the storage does.
 */
@Entity
@Table(name = "task")
public class TaskEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    private String project;

    @Enumerated(EnumType.STRING)
    private TaskStatus status;

    protected TaskEntity() {
        // JPA requires a no-arg constructor.
    }

    public TaskEntity(String title, String project, TaskStatus status) {
        this.title = title;
        this.project = project;
        this.status = status;
    }

    public Task toDomain() {
        return new Task(id, title, project, status);
    }

    public Long getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getProject() {
        return project;
    }

    public TaskStatus getStatus() {
        return status;
    }
}
