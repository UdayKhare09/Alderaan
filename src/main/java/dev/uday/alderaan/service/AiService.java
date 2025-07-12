package dev.uday.alderaan.service;

import dev.uday.alderaan.model.ChatMessage;
import dev.uday.alderaan.model.ChatSession;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.ollama.OllamaChatModel;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
public class AiService {

    private final ChatClient chatClient;
    private final SpeechSynthesisService speechSynthesisService;
    private final ChatService chatService;

    @Value("${ollama.system.instructions:You are a helpful AI assistant. Provide short responses like chatting face to face without markdown, emojis, or code blocks.}")
    private String systemInstructions;

    @Value("${ollama.max.history.messages:20}")
    private int maxHistoryMessages;

    public AiService(SpeechSynthesisService speechSynthesisService, OllamaChatModel chatModel, ChatService chatService) {
        this.speechSynthesisService = speechSynthesisService;
        this.chatService = chatService;
        this.chatClient = ChatClient.create(chatModel);
    }

    public String getTextResponse(String prompt) {
        try {
            log.debug("Sending prompt to Ollama: {}", prompt);
            String fullPrompt = systemInstructions + "\n\nUser: " + prompt + "\nAssistant:";
            return getResponse(fullPrompt);
        } catch (Exception e) {
            log.error("Error getting response from Ollama", e);
            return "Sorry, I'm having trouble processing your request right now.";
        }
    }

    public String getTextResponseWithHistory(String prompt, ChatSession session) {
        try {
            log.debug("Sending prompt with history to Ollama: {}", prompt);
            String fullPrompt = buildPromptWithHistory(prompt, session);
            return getResponse(fullPrompt);
        } catch (Exception e) {
            log.error("Error getting response with history from Ollama", e);
            return "Sorry, I'm having trouble processing your request right now.";
        }
    }

    public byte[] getSpeechResponse(String prompt) {
        String textResponse = getTextResponse(prompt);
        return speechSynthesisService.synthesizeSpeech(textResponse);
    }

    public byte[] getSpeechResponseWithHistory(String prompt, ChatSession session) {
        String textResponse = getTextResponseWithHistory(prompt, session);
        return speechSynthesisService.synthesizeSpeech(textResponse);
    }

    private String getResponse(String fullPrompt) {
        String response = chatClient
                .prompt(fullPrompt)
                .call()
                .content();

        log.debug("Received response from Ollama: {}", response);
        return response;
    }

    private String buildPromptWithHistory(String currentPrompt, ChatSession session) {
        StringBuilder promptBuilder = new StringBuilder();
        promptBuilder.append(systemInstructions).append("\n\n");

        // Get recent messages from the session
        List<ChatMessage> recentMessages = chatService.getSessionMessages(session)
                .stream()
                .filter(msg -> msg.getType() == ChatMessage.MessageType.USER_TEXT ||
                        msg.getType() == ChatMessage.MessageType.USER_AUDIO ||
                        msg.getType() == ChatMessage.MessageType.AI_TEXT ||
                        msg.getType() == ChatMessage.MessageType.AI_AUDIO)
                .sorted(Comparator.comparing(ChatMessage::getCreatedAt))
                .collect(Collectors.toList());

        // Limit to recent messages to avoid token limits
        int startIndex = Math.max(0, recentMessages.size() - maxHistoryMessages);
        recentMessages = recentMessages.subList(startIndex, recentMessages.size());

        // Build conversation history
        for (ChatMessage message : recentMessages) {
            if (isUserMessage(message.getType())) {
                promptBuilder.append("User: ").append(message.getContent()).append("\n");
            } else if (isAiMessage(message.getType())) {
                promptBuilder.append("Assistant: ").append(message.getContent()).append("\n");
            }
        }

        // Add current prompt
        promptBuilder.append("User: ").append(currentPrompt).append("\n");
        promptBuilder.append("Assistant:");

        return promptBuilder.toString();
    }

    private boolean isUserMessage(ChatMessage.MessageType type) {
        return type == ChatMessage.MessageType.USER_TEXT || type == ChatMessage.MessageType.USER_AUDIO;
    }

    private boolean isAiMessage(ChatMessage.MessageType type) {
        return type == ChatMessage.MessageType.AI_TEXT || type == ChatMessage.MessageType.AI_AUDIO;
    }
}