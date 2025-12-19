package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.Building;
import be.delomid.oneapp.mschat.mschat.model.FaqTopic;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FaqTopicRepository extends JpaRepository<FaqTopic, Long> {

    List<FaqTopic> findFaqTopicByBuilding(Building building);
}
