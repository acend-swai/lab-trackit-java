package ch.acend.trackit.repository;

import ch.acend.trackit.domain.CommentEntity;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CommentRepository extends JpaRepository<CommentEntity, Long> {

    List<CommentEntity> findByTaskIdOrderByCreatedAtAsc(long taskId);
}
