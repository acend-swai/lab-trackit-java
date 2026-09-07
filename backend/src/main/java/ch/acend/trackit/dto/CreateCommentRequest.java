package ch.acend.trackit.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * The bounds come from the spec, not from a guess: a comment needs an author, and a body
 * of 1 to 2000 characters.
 */
public record CreateCommentRequest(
        @NotBlank String author,
        @NotBlank @Size(max = 2000) String body) {
}
