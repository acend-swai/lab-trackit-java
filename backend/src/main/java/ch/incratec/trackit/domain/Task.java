package ch.incratec.trackit.domain;

/**
 * A task as the API shapes it. A value type - no framework annotations, equality by
 * value. Persistence in M2 adds an entity next to this record.
 */
public record Task(long id, String title, String project, TaskStatus status) {
}
