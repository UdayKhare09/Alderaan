package dev.uday.alderaan.service;

import io.github.ollama4j.OllamaAPI;
import io.github.ollama4j.models.OllamaResult;
import io.github.ollama4j.utils.OptionsBuilder;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class AiService {

    private final OllamaAPI ollamaAPI;
    private final SpeechSynthesisService speechSynthesisService;

    @Value("${ollama.model:gemma3:1b}")
    private String model;

    public AiService(SpeechSynthesisService speechSynthesisService,
                     @Value("${ollama.host:http://localhost:11434}") String ollamaHost) {
        this.speechSynthesisService = speechSynthesisService;
        this.ollamaAPI = new OllamaAPI(ollamaHost);
        this.ollamaAPI.setRequestTimeoutSeconds(60);
    }

    @Value("${ollama.system.instructions:You are a helpful AI assistant. Provide short responses like chatting face to face without markdown.}")
    private String systemInstructions;

    public String getTextResponse(String prompt) {
        try {
            log.debug("Sending prompt to Ollama: {}", prompt);

            String fullPrompt = systemInstructions + "\n\nUser: " + prompt + "\nAssistant:";

            OllamaResult result = ollamaAPI.generate(model, fullPrompt, false,
                    new OptionsBuilder().setTemperature(0.7f).build());

            String response = result.getResponse();
            log.debug("Received response from Ollama: {}", response);

            return response;
        } catch (Exception e) {
            log.error("Error getting response from Ollama", e);
            return "Sorry, I'm having trouble processing your request right now.";
        }
    }

    public byte[] getSpeechResponse(String prompt) {
        String textResponse = getTextResponse(prompt);
        return speechSynthesisService.synthesizeSpeech(textResponse);
    }
}