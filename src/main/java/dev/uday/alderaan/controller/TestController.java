package dev.uday.alderaan.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/test")
public class TestController {

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of(
                "status", "OK",
                "message", "Backend is running",
                "timestamp", System.currentTimeMillis()
        ));
    }

    @PostMapping("/echo")
    public ResponseEntity<Map<String, Object>> echo(@RequestBody Map<String, Object> payload) {
        return ResponseEntity.ok(Map.of(
                "received", payload,
                "timestamp", System.currentTimeMillis()
        ));
    }
}