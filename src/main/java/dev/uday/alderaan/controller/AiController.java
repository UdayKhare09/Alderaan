package dev.uday.alderaan.controller;

import dev.uday.alderaan.model.ChatMessage;
import dev.uday.alderaan.model.ChatSession;
import dev.uday.alderaan.model.User;
import dev.uday.alderaan.service.AiService;
import dev.uday.alderaan.service.ChatService;
import dev.uday.alderaan.service.SpeechRecognitionService;
import dev.uday.alderaan.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
@Slf4j
public class AiController {

    private final AiService aiService;
    private final SpeechRecognitionService speechRecognitionService;
    private final ChatService chatService;
    private final UserService userService;

    @PostMapping("/chat")
    public ResponseEntity<Map<String, Object>> chat(
            @RequestParam("prompt") String prompt,
            @RequestParam("sessionId") Long sessionId,
            Authentication authentication) {

        log.debug("Received chat request: {} for session: {}", prompt, sessionId);

        try {
            User user = userService.findByUsername(authentication.getName());
            ChatSession session = chatService.getChatSessionById(sessionId)
                    .orElseThrow(() -> new RuntimeException("Session not found"));

            // Save user message
            ChatMessage userMessage = chatService.saveMessage(session, ChatMessage.MessageType.USER_TEXT, prompt);

            // Get AI response
            String aiResponse = aiService.getTextResponse(prompt);

            // Save AI response
            ChatMessage aiMessage = chatService.saveMessage(session, ChatMessage.MessageType.AI_TEXT, aiResponse);

            Map<String, Object> result = new HashMap<>();
            result.put("userMessage", Map.of(
                    "id", userMessage.getId(),
                    "content", userMessage.getContent(),
                    "type", userMessage.getType(),
                    "createdAt", userMessage.getCreatedAt()
            ));
            result.put("aiMessage", Map.of(
                    "id", aiMessage.getId(),
                    "content", aiMessage.getContent(),
                    "type", aiMessage.getType(),
                    "createdAt", aiMessage.getCreatedAt()
            ));

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("Error processing chat request", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                    Map.of("error", "Failed to process chat request")
            );
        }
    }

    @PostMapping("/chat/speech")
    public ResponseEntity<byte[]> chatWithSpeech(
            @RequestParam("prompt") String prompt,
            @RequestParam("sessionId") Long sessionId,
            Authentication authentication) {

        log.debug("Received chat with speech request: {} for session: {}", prompt, sessionId);

        try {
            User user = userService.findByUsername(authentication.getName());
            ChatSession session = chatService.getChatSessionById(sessionId)
                    .orElseThrow(() -> new RuntimeException("Session not found"));

            // Save user message
            chatService.saveMessage(session, ChatMessage.MessageType.USER_TEXT, prompt);

            // Get AI response with speech
            byte[] audioData = aiService.getSpeechResponse(prompt);
            String aiResponse = aiService.getTextResponse(prompt);

            // Save AI response (we'll need to save the audio file path)
            chatService.saveMessage(session, ChatMessage.MessageType.AI_AUDIO, aiResponse);

            if (audioData.length == 0) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("audio/wav"));
            headers.setContentLength(audioData.length);
            headers.set("Content-Disposition", "attachment; filename=\"ai_response.wav\"");

            return new ResponseEntity<>(audioData, headers, HttpStatus.OK);
        } catch (Exception e) {
            log.error("Error processing speech chat request", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    @PostMapping("/chat/voice")
    public ResponseEntity<byte[]> voiceToVoice(
            @RequestParam("audio") MultipartFile audioFile,
            @RequestParam("sessionId") Long sessionId,
            Authentication authentication) {

        log.debug("Received voice-to-voice request for session: {}, file: {}, size: {}",
                sessionId, audioFile.getOriginalFilename(), audioFile.getSize());

        try {
            User user = userService.findByUsername(authentication.getName());
            ChatSession session = chatService.getChatSessionById(sessionId)
                    .orElseThrow(() -> new RuntimeException("Session not found"));

            // Recognize speech from audio
            String recognizedText = speechRecognitionService.recognizeSpeech(audioFile);
            log.debug("Recognized text: {}", recognizedText);

            if (recognizedText == null || recognizedText.trim().isEmpty()) {
                log.warn("No text recognized from audio");
                return ResponseEntity.badRequest().body(null);
            }

            // Save user audio message
            chatService.saveMessage(session, ChatMessage.MessageType.USER_AUDIO, recognizedText);

            // Get AI response and synthesize speech
            byte[] audioResponse = aiService.getSpeechResponse(recognizedText);
            String aiResponse = aiService.getTextResponse(recognizedText);

            // Save AI audio response
            chatService.saveMessage(session, ChatMessage.MessageType.AI_AUDIO, aiResponse);

            if (audioResponse.length == 0) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("audio/wav"));
            headers.setContentLength(audioResponse.length);
            headers.set("Content-Disposition", "attachment; filename=\"voice_response.wav\"");

            return new ResponseEntity<>(audioResponse, headers, HttpStatus.OK);

        } catch (Exception e) {
            log.error("Error processing voice-to-voice request", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
}