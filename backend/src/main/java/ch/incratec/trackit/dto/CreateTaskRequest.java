package ch.incratec.trackit.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Payload for POST /api/v1/tasks. Accepted only, never returned - the controller
 * answers with the domain record.
 */
public record CreateTaskRequest(
        @NotBlank String title,
        @NotBlank String project) {
}
