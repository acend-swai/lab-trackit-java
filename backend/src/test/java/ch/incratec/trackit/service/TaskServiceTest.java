package ch.incratec.trackit.service;

import static org.assertj.core.api.Assertions.assertThat;

import ch.incratec.trackit.domain.Task;
import ch.incratec.trackit.domain.TaskStatus;
import org.junit.jupiter.api.Test;

class TaskServiceTest {

    private final TaskService taskService = new TaskService();

    @Test
    void createReturnsOpenTaskWithId() {
        Task task = taskService.create("Write the ADR", "trackit");

        assertThat(task.id()).isEqualTo(1L);
        assertThat(task.title()).isEqualTo("Write the ADR");
        assertThat(task.project()).isEqualTo("trackit");
        assertThat(task.status()).isEqualTo(TaskStatus.OPEN);
    }

    @Test
    void createAssignsAnIdPerTask() {
        Task first = taskService.create("First", "trackit");
        Task second = taskService.create("Second", "trackit");

        assertThat(first.id()).isNotEqualTo(second.id());
    }

    @Test
    void findAllReturnsTasksInCreationOrder() {
        taskService.create("First", "trackit");
        taskService.create("Second", "trackit");

        assertThat(taskService.findAll())
                .extracting(Task::title)
                .containsExactly("First", "Second");
    }

    @Test
    void findAllIsEmptyBeforeAnyTaskIsCreated() {
        assertThat(taskService.findAll()).isEmpty();
    }
}
