package ch.acend.trackit.web;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import ch.acend.trackit.domain.Task;
import ch.acend.trackit.domain.TaskStatus;
import ch.acend.trackit.dto.CreateTaskRequest;
import ch.acend.trackit.service.TaskService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/**
 * The service now reaches PostgreSQL, so it is mocked here rather than imported.
 * A green run of this class says the web layer is correct. It says nothing about
 * persistence - that is proven by restarting the application and seeing the row
 * survive.
 */
@WebMvcTest(TaskController.class)
class TaskControllerTest {

    private static final String ONE_TASK = """
            {"title":"Write the context file","project":"trackit"}
            """;

    private static final Task STORED_TASK =
            new Task(1L, "Write the context file", "trackit", TaskStatus.OPEN);

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private TaskService taskService;

    @Test
    void postTaskReturnsCreated() throws Exception {
        when(taskService.create(any(CreateTaskRequest.class))).thenReturn(STORED_TASK);

        mockMvc.perform(post("/api/v1/tasks")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(ONE_TASK))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.title").value("Write the context file"))
                .andExpect(jsonPath("$.status").value("OPEN"));
    }

    @Test
    void postTaskWithoutTitleReturnsBadRequest() throws Exception {
        mockMvc.perform(post("/api/v1/tasks")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"\",\"project\":\"trackit\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void getTasksReturnsTheStoredTask() throws Exception {
        when(taskService.findAll()).thenReturn(List.of(STORED_TASK));

        mockMvc.perform(get("/api/v1/tasks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].project").value("trackit"));
    }
}
