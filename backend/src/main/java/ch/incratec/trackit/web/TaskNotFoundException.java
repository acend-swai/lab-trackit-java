package ch.incratec.trackit.web;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/** Thrown when a task id does not exist. Spring maps it to 404 for us. */
@ResponseStatus(HttpStatus.NOT_FOUND)
public class TaskNotFoundException extends RuntimeException {

    public TaskNotFoundException(long id) {
        super("No task with id " + id);
    }
}
