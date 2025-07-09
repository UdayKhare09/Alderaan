package dev.uday.alderaan.repository;

import dev.uday.alderaan.model.ChatSession;
import dev.uday.alderaan.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatSessionRepository extends JpaRepository<ChatSession, Long> {
    List<ChatSession> findByUserOrderByCreatedAtDesc(User user);
    List<ChatSession> findByUserIdOrderByCreatedAtDesc(Long userId);
}