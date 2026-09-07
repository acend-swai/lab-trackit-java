package ch.incratec.trackit.web;

import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import ch.incratec.trackit.domain.Task;
import ch.incratec.trackit.domain.TaskStatus;
import ch.incratec.trackit.service.TaskService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(TaskController.class)
class TaskControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private TaskService taskService;

    @Test
    void postTaskReturnsCreated() throws Exception {
        given(taskService.create("Write the ADR", "trackit"))
                .willReturn(new Task(1L, "Write the ADR", "trackit", TaskStatus.OPEN));

        mockMvc.perform(post("/api/v1/tasks")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Write the ADR\",\"project\":\"trackit\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.title").value("Write the ADR"))
                .andExpect(jsonPath("$.project").value("trackit"))
                .andExpect(jsonPath("$.status").value("OPEN"));
    }

    @Test
    void postTaskWithBlankTitleReturnsBadRequest() throws Exception {
        mockMvc.perform(post("/api/v1/tasks")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"  \",\"project\":\"trackit\"}"))
                .andExpect(status().isBadRequest());

        verifyNoInteractions(taskService);
    }

    @Test
    void getTasksReturnsAllTasks() throws Exception {
        given(taskService.findAll()).willReturn(List.of(
                new Task(1L, "Write the ADR", "trackit", TaskStatus.OPEN),
                new Task(2L, "Ship the lab", "trackit", TaskStatus.DONE)));

        mockMvc.perform(get("/api/v1/tasks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].id").value(1))
                .andExpect(jsonPath("$[0].status").value("OPEN"))
                .andExpect(jsonPath("$[1].title").value("Ship the lab"))
                .andExpect(jsonPath("$[1].status").value("DONE"));
    }

    @Test
    void getTasksReturnsEmptyListWhenNoneExist() throws Exception {
        given(taskService.findAll()).willReturn(List.of());

        mockMvc.perform(get("/api/v1/tasks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }
}
