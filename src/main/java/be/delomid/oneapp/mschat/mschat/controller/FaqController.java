package be.delomid.oneapp.mschat.mschat.controller;


import be.delomid.oneapp.mschat.mschat.model.FaqTopic;
import be.delomid.oneapp.mschat.mschat.service.FaqService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/faq")
@RequiredArgsConstructor
@Slf4j
public class FaqController {
    private final FaqService faqService;

    @GetMapping("/getAllTopics/{buildingId}")
    public List<FaqTopic> getAllTopics(@PathVariable String buildingId) {
        return faqService.getAllTopics(buildingId);
    }

    @GetMapping("/{id}")
    public FaqTopic getTopicById(@PathVariable Long id) {
        return faqService.getTopic(id);
    }

    @PostMapping("/{buildingId}")
    @ResponseStatus(HttpStatus.CREATED)
    public FaqTopic createTopic(@RequestBody FaqTopic topic,@PathVariable String buildingId) {
        return faqService.saveTopic(topic,buildingId);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteTopic(@PathVariable Long id) {
        faqService.deleteTopic(id);
    }
}
