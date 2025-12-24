package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.service.SpeechToTextService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/speech-to-text")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Speech to Text", description = "Transcription vocale avec OpenAI Whisper")
public class SpeechToTextController {

    private final SpeechToTextService speechToTextService;

    @PostMapping("/transcribe")
    @Operation(summary = "Transcribe audio to text using OpenAI Whisper")
    public ResponseEntity<Map<String, String>> transcribeAudio(
            @RequestParam("audio") MultipartFile audioFile) {

        log.info("Received audio file for transcription: {}, size: {} bytes",
                audioFile.getOriginalFilename(), audioFile.getSize());

        try {
            if (audioFile.isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "Audio file is empty");
                return ResponseEntity.badRequest().body(errorResponse);
            }

            String transcription = speechToTextService.transcribeAudio(audioFile);

            Map<String, String> response = new HashMap<>();
            response.put("transcription", transcription);
            response.put("status", "success");

            log.info("Transcription successful: {}", transcription);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error transcribing audio", e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to transcribe audio: " + e.getMessage());
            errorResponse.put("status", "error");
            return ResponseEntity.internalServerError().body(errorResponse);
        }
    }
}
