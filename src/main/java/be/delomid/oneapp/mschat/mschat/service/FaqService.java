package be.delomid.oneapp.mschat.mschat.service;


import be.delomid.oneapp.mschat.mschat.model.Building;
import be.delomid.oneapp.mschat.mschat.model.FaqTopic;
import be.delomid.oneapp.mschat.mschat.repository.BuildingRepository;
import be.delomid.oneapp.mschat.mschat.repository.FaqTopicRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class FaqService {
    private final FaqTopicRepository topicRepository;
    private final BuildingRepository buildingRepository;

    public List<FaqTopic> getAllTopics(String buildingId) {
        Building building = buildingRepository.findById(buildingId).orElseThrow();
        // charge les questions en lazy, elles seront sérialisées au besoin
        return topicRepository.findFaqTopicByBuilding(building);
    }
    public FaqTopic getTopic(Long id) {
        return topicRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Topic not found : " + id));
    }
    public FaqTopic saveTopic(FaqTopic topic,String buildingId) {
        // cascade ALL -> les questions associées seront sauvées aussi
        Building building = buildingRepository.findById(buildingId).orElseThrow();

        topic.setBuilding(building);
        FaqTopic savedTopic = topicRepository.save(topic);
        building.getFaqTopics().add(savedTopic);
        return savedTopic;
    }

    public void deleteTopic(Long id) {
        topicRepository.deleteById(id);
    }

}
