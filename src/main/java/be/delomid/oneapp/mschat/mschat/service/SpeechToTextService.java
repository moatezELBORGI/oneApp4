package be.delomid.oneapp.mschat.mschat.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class SpeechToTextService {

    @Value("${openai.api.key}")
    private String openaiApiKey;

    @Value("${openai.api.base-url}")
    private String openaiBaseUrl;

    private final RestTemplate restTemplate = new RestTemplate();

    public String transcribeAudio(MultipartFile audioFile) throws IOException {
        File tempFile = File.createTempFile("audio", ".webm");

        try {
            try (FileOutputStream fos = new FileOutputStream(tempFile)) {
                fos.write(audioFile.getBytes());
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);
            headers.setBearerAuth(openaiApiKey);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", new org.springframework.core.io.FileSystemResource(tempFile));
            body.add("model", "whisper-1");
            body.add("language", "fr");

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            String url = openaiBaseUrl + "/audio/transcriptions";

            ResponseEntity<Map> response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    requestEntity,
                    Map.class
            );

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> responseBody = response.getBody();
                return (String) responseBody.get("text");
            } else {
                log.error("OpenAI API returned non-OK status: {}", response.getStatusCode());
                throw new RuntimeException("Failed to transcribe audio");
            }

        } finally {
            if (tempFile.exists()) {
                tempFile.delete();
            }
        }
    }
}
