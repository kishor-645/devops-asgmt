package com.example.demo;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}

@Entity @Data @NoArgsConstructor @AllArgsConstructor
class Message {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String content;
}

interface MessageRepository extends JpaRepository<Message, Long> {}

@RestController
@RequestMapping("/api/messages")
@RequiredArgsConstructor
class MessageController {
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final MessageRepository repository;

    @PostMapping
    public String sendMessage(@RequestBody String message) {
        kafkaTemplate.send("devops-topic", message);
        return "Sent: " + message;
    }

    @GetMapping
    public List<Message> getMessages() {
        return repository.findAll();
    }
}

@Service
@RequiredArgsConstructor
class MessageConsumer {
    private final MessageRepository repository;

    @KafkaListener(topics = "devops-topic", groupId = "devops-group")
    public void consume(String message) {
        Message msg = new Message();
        msg.setContent(message);
        repository.save(msg);
    }
}