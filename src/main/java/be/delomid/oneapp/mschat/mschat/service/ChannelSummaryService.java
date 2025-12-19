package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.model.Channel;
import be.delomid.oneapp.mschat.mschat.model.Message;
import be.delomid.oneapp.mschat.mschat.model.MessageType;
import be.delomid.oneapp.mschat.mschat.repository.ChannelRepository;
import be.delomid.oneapp.mschat.mschat.repository.MessageRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class ChannelSummaryService {

    private final ChannelRepository channelRepository;
    private final MessageRepository messageRepository;
    private final ChatClient chatClient;

    public String generateOnlyAiSummary(Long channelId) {

        Channel channel = channelRepository.findById(channelId)
                .orElseThrow(() -> new EntityNotFoundException("Channel not found: " + channelId));

        List<Message> messages = messageRepository.findByChannelIdOrderByCreatedAtDesc(channelId);

        if (messages.isEmpty()) {
            return "Aucun message dans ce canal.";
        }

        List<Message> safeMessages = messages.stream()
                .filter(m -> m != null
                        && m.getType() == MessageType.TEXT
                        && Boolean.FALSE.equals(m.getIsDeleted()))
                .limit(200)
                .collect(Collectors.toList());

        String conversation = safeMessages.stream()
                .map(m -> "[" + m.getSenderId() + "]: " + sanitize(m.getContent()))
                .collect(Collectors.joining("\n"));

        String prompt = """
                Tu es un expert en gestion immobilière et copropriété.

                Canal : « %s » %s

                === CONVERSATION ===
                %s

                Résume cette conversation en français de façon claire et professionnelle :
                • Résumé exécutif (2-3 phrases)
                • Problèmes identifiés (avec émojis de gravité)
                • Actions en cours
                • Décisions prises / coûts
                • Prochaines étapes

                Utilise des puces et des émojis. Sois concis.
                """.formatted(
                channel.getName(),
                channel.getDescription() != null ? " — " + sanitize(channel.getDescription()) : "",
                conversation
        );

        return callOpenAI(prompt);
    }

    private String callOpenAI(String prompt) {
        return chatClient.prompt(prompt)
                .call()
                .content();  // renvoie la réponse texte
    }

    private String sanitize(String input) {
        if (input == null) return "";
        return input
                .replace("`", "'")
                .replace("<", "(")
                .replace(">", ")");
    }
}
