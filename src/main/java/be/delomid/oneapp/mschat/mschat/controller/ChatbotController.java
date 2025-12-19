package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.service.FaqChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;


import be.delomid.oneapp.mschat.mschat.service.FaqChatService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/chat")
@RequiredArgsConstructor
public class ChatbotController {

    private final FaqChatService faqChatService;

    @PostMapping("/ask")
    public Map<String, Object> ask(@RequestBody ChatRequest request) {
        return faqChatService.chat(request.getMessage(), request.getBuildingId());
    }

    @Data
    public static class ChatRequest {
        private String message;
        private String buildingId;
    }
}

