package dev.uday.alderaan.controller;

import dev.uday.alderaan.model.ChatMessage;
import dev.uday.alderaan.model.ChatSession;
import dev.uday.alderaan.model.User;
import dev.uday.alderaan.service.ChatService;
import dev.uday.alderaan.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
@Slf4j
public class ChatController {

    private final ChatService chatService;
    private final UserService userService;

    @PostMapping("/sessions")
    public ResponseEntity<Map<String, Object>> createChatSession(
            @RequestBody Map<String, String> request,
            Authentication authentication) {

        String title = request.get("title");
        User user = userService.findByUsername(authentication.getName());

        ChatSession session = chatService.createChatSession(user, title);

        Map<String, Object> response = new HashMap<>();
        response.put("id", session.getId());
        response.put("title", session.getTitle());
        response.put("createdAt", session.getCreatedAt());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/sessions")
    public ResponseEntity<List<ChatSession>> getUserChatSessions(Authentication authentication) {
        User user = userService.findByUsername(authentication.getName());
        List<ChatSession> sessions = chatService.getUserChatSessions(user);
        return ResponseEntity.ok(sessions);
    }

    @GetMapping("/sessions/{sessionId}")
    public ResponseEntity<ChatSession> getChatSession(
            @PathVariable Long sessionId,
            Authentication authentication) {

        return chatService.getChatSessionById(sessionId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/sessions/{sessionId}/messages")
    public ResponseEntity<List<ChatMessage>> getSessionMessages(
            @PathVariable Long sessionId,
            Authentication authentication) {

        return chatService.getChatSessionById(sessionId)
                .map(session -> {
                    List<ChatMessage> messages = chatService.getSessionMessages(session);
                    return ResponseEntity.ok(messages);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/sessions/{sessionId}")
    public ResponseEntity<Void> deleteChatSession(
            @PathVariable Long sessionId,
            Authentication authentication) {

        chatService.deleteChatSession(sessionId);
        return ResponseEntity.ok().build();
    }
}