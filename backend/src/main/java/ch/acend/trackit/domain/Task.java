package ch.acend.trackit.domain;

/** One task in TrackIt. Persistence arrives in M2; for now tasks live in memory. */
public record Task(long id, String title, String project, TaskStatus status) {
}
