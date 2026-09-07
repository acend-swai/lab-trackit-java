package ch.acend.trackit.domain;

import java.time.Instant;

/** One comment on a task. The API shape, with no framework annotations. */
public record Comment(long id, long taskId, String author, String body, Instant createdAt) {
}
