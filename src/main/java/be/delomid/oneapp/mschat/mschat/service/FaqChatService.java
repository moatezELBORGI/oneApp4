package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.model.FaqQuestion;
import be.delomid.oneapp.mschat.mschat.model.FaqTopic;
import be.delomid.oneapp.mschat.mschat.model.FaqVector;
import lombok.RequiredArgsConstructor;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.embedding.EmbeddingRequest;
import org.springframework.ai.embedding.EmbeddingResponse;
import org.springframework.ai.openai.OpenAiEmbeddingModel;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class FaqChatService {

    private final FaqService faqService;
    private final ChatClient chatClient;
    private final OpenAiEmbeddingModel embeddingModel;

    private final double SIMILARITY_THRESHOLD = 0.65;

    public Map<String, Object> chat(String message, String buildingId) {

        // 1️⃣ Charger toutes les FAQ du bâtiment
        List<FaqTopic> topics = faqService.getAllTopics(buildingId);

        List<FaqVector> vectors = buildVectors(topics);

        // 2️⃣ Générer embedding question utilisateur
        EmbeddingResponse embeddingUser = embeddingModel.call(
                new EmbeddingRequest(List.of(message), null)
        );

        float[] userVectorFloat = embeddingUser.getResults().get(0).getOutput();
        double[] userVector = floatToDouble(userVectorFloat);

        // 3️⃣ Comparer similarité cosine
        FaqVector bestMatch = null;
        double bestScore = 0.0;

        for (FaqVector vec : vectors) {
            double score = cosineSimilarity(vec.getEmbedding(), userVector);

            if (score > bestScore) {
                bestScore = score;
                bestMatch = vec;
            }
        }

        // 4️⃣ Si FAQ trouvée (RAG)
        if (bestMatch != null && bestScore >= SIMILARITY_THRESHOLD) {
            Map<String, Object> result = new HashMap<>();
            result.put("type", "faq");
            result.put("answer", bestMatch.getAnswer());
            result.put("score", bestScore);
            result.put("question", bestMatch.getQuestion());
            return result;
        }

        // 5️⃣ Fallback vers OpenAI LLM
        return callLLM(message, topics);
    }

    private String buildSystemPrompt(List<FaqTopic> topics) {

        StringBuilder prompt = new StringBuilder("""
        You are a helpful real estate assistant for a property management platform.
        You answer questions related to building rules, rent, payments, maintenance,
        services, community matters, and resident life.

        ALWAYS base your answer on the available FAQ topics and their questions when possible.
        If the information is not available, provide a general real-estate appropriate answer
        based on best practices and clarity.

        --- Available FAQ Topics for this Building ---
        """);

        for (FaqTopic topic : topics) {
            prompt.append("\n• ").append(topic.getName());
        }

        prompt.append("\n\n--- Reference FAQ Content (use when relevant) ---\n");

        topics.forEach(topic -> {
            prompt.append("\n\nTopic: ").append(topic.getName());

            topic.getQuestions().stream()
                    .limit(3) // Limit context to avoid long prompts
                    .forEach(q -> {
                        prompt.append("\nQ: ").append(q.getQuestion());
                        prompt.append("\nA: ").append(q.getAnswer());
                    });
        });

        prompt.append("""
        
        --- Instructions ---
        - If a FAQ answer exists, summarize it politely and clearly.
        - If no FAQ matches, respond naturally using general building-management knowledge.
        - Keep answers short, clean, and helpful.
        - Never mention embeddings or similarity scores.
        - Never invent rules that contradict provided FAQ context.
        """);

        return prompt.toString();
    }

    private Map<String, Object> callLLM(String message, List<FaqTopic> topics) {

        String systemPrompt = buildSystemPrompt(topics);

        String response = chatClient.prompt()
                .system(systemPrompt)
                .user(message)
                .call()
                .content();

        Map<String, Object> result = new HashMap<>();
        result.put("type", "llm");
        result.put("answer", response);
        result.put("score", 0.0);
        result.put("question", null);
        return result;
    }

    private List<FaqVector> buildVectors(List<FaqTopic> topics) {

        List<FaqVector> vectors = new ArrayList<>();

        // A. récupérer toutes les questions
        List<String> questions = topics.stream()
                .flatMap(t -> t.getQuestions().stream())
                .map(FaqQuestion::getQuestion)
                .toList();

        if (questions.isEmpty()) return vectors;

        // B. embeddings FAQ
        EmbeddingResponse embeddingResponse = embeddingModel.call(
                new EmbeddingRequest(questions, null)
        );

        int index = 0;
        for (FaqTopic topic : topics) {
            for (FaqQuestion q : topic.getQuestions()) {

                float[] embeddingFloat = embeddingResponse.getResults().get(index).getOutput();
                double[] embedding = floatToDouble(embeddingFloat);

                vectors.add(new FaqVector(
                        q.getId(),
                        q.getQuestion(),
                        q.getAnswer(),
                        embedding
                ));
                index++;
            }
        }

        return vectors;
    }

    private double cosineSimilarity(double[] a, double[] b) {
        double dot = 0.0, normA = 0.0, normB = 0.0;
        for (int i = 0; i < a.length; i++) {
            dot += a[i] * b[i];
            normA += Math.pow(a[i], 2);
            normB += Math.pow(b[i], 2);
        }
        return dot / (Math.sqrt(normA) * Math.sqrt(normB));
    }

    private double[] floatToDouble(float[] floatArray) {
        double[] doubleArray = new double[floatArray.length];
        for (int i = 0; i < floatArray.length; i++) {
            doubleArray[i] = floatArray[i];
        }
        return doubleArray;
    }
}