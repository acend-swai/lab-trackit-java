package ch.acend.trackit.web;

import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import ch.acend.trackit.domain.Comment;
import ch.acend.trackit.dto.CreateCommentRequest;
import ch.acend.trackit.service.CommentService;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/**
 * One test per acceptance scenario in
 * openspec/changes/archive/2026-09-08-add-task-comments/specs/task-comments/spec.md.
 * Written from the spec before the implementation existed.
 */
@WebMvcTest(CommentController.class)
class CommentControllerTest {

    private static final String ONE_COMMENT =
            """
            {"author":"alice","body":"The restart check found this."}
            """;

    private static final Comment STORED_COMMENT =
            new Comment(1L, 7L, "alice", "The restart check found this.", Instant.EPOCH);

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private CommentService commentService;

    @Test
    void postCommentReturnsCreated() throws Exception {
        when(commentService.create(anyLong(), any(CreateCommentRequest.class)))
                .thenReturn(STORED_COMMENT);

        mockMvc.perform(post("/api/v1/tasks/7/comments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(ONE_COMMENT))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.taskId").value(7))
                .andExpect(jsonPath("$.author").value("alice"));
    }

    @Test
    void postCommentWithoutAuthorReturnsBadRequest() throws Exception {
        mockMvc.perform(post("/api/v1/tasks/7/comments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"author\":\"\",\"body\":\"no author\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void postCommentWithEmptyBodyReturnsBadRequest() throws Exception {
        mockMvc.perform(post("/api/v1/tasks/7/comments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"author\":\"alice\",\"body\":\"\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void postCommentLongerThanTheLimitReturnsBadRequest() throws Exception {
        String tooLong = "x".repeat(2001);
        mockMvc.perform(post("/api/v1/tasks/7/comments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"author\":\"alice\",\"body\":\"" + tooLong + "\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void postCommentOnUnknownTaskReturnsNotFound() throws Exception {
        when(commentService.create(anyLong(), any(CreateCommentRequest.class)))
                .thenThrow(new TaskNotFoundException(404L));

        mockMvc.perform(post("/api/v1/tasks/404/comments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(ONE_COMMENT))
                .andExpect(status().isNotFound());
    }

    @Test
    void getCommentsReturnsThemOldestFirst() throws Exception {
        Comment later = new Comment(2L, 7L, "bob", "Second.", Instant.EPOCH.plusSeconds(60));
        when(commentService.findByTask(7L)).thenReturn(List.of(STORED_COMMENT, later));

        mockMvc.perform(get("/api/v1/tasks/7/comments"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].author").value("alice"))
                .andExpect(jsonPath("$[1].author").value("bob"));
    }

    @Test
    void getCommentsForUnknownTaskReturnsNotFound() throws Exception {
        when(commentService.findByTask(404L)).thenThrow(new TaskNotFoundException(404L));

        mockMvc.perform(get("/api/v1/tasks/404/comments"))
                .andExpect(status().isNotFound());
    }
}
