package ch.acend.trackit.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateTaskRequest(
        @NotBlank String title,
        @NotBlank String project) {
}
