package ch.acend.trackit.web;

import ch.acend.trackit.domain.Comment;
import ch.acend.trackit.dto.CreateCommentRequest;
import ch.acend.trackit.service.CommentService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/tasks/{taskId}/comments")
public class CommentController {

    private final CommentService commentService;

    public CommentController(CommentService commentService) {
        this.commentService = commentService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Comment createComment(
            @PathVariable long taskId, @Valid @RequestBody CreateCommentRequest request) {
        return commentService.create(taskId, request);
    }

    @GetMapping
    public List<Comment> listComments(@PathVariable long taskId) {
        return commentService.findByTask(taskId);
    }
}
