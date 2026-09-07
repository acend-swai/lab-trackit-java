package ch.acend.trackit.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * The stored shape of a comment. A separate class from the {@link Comment} record, the
 * same way {@link TaskEntity} sits beside {@link Task}.
 */
@Entity
@Table(name = "comment")
public class CommentEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "task_id", nullable = false)
    private Long taskId;

    private String author;

    private String body;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected CommentEntity() {
        // JPA requires a no-arg constructor.
    }

    public CommentEntity(Long taskId, String author, String body, Instant createdAt) {
        this.taskId = taskId;
        this.author = author;
        this.body = body;
        this.createdAt = createdAt;
    }

    public Comment toDomain() {
        return new Comment(id, taskId, author, body, createdAt);
    }

    public Long getId() {
        return id;
    }

    public Long getTaskId() {
        return taskId;
    }

    public String getAuthor() {
        return author;
    }

    public String getBody() {
        return body;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
