package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.FaqQuestion;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FaqQuestionRepository extends JpaRepository<FaqQuestion, Long> {
}