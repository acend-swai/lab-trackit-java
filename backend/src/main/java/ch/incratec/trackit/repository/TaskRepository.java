package ch.incratec.trackit.repository;

import ch.incratec.trackit.domain.TaskEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TaskRepository extends JpaRepository<TaskEntity, Long> {
}
