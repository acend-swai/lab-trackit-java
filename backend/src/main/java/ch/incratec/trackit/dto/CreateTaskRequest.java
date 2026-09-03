package ch.incratec.trackit.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateTaskRequest(
        @NotBlank String title,
        @NotBlank String project) {
}
