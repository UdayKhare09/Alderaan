package dev.uday.alderaan.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.vosk.LibVosk;
import org.vosk.LogLevel;
import org.vosk.Model;
import org.vosk.Recognizer;
import org.springframework.core.io.ResourceLoader;
import org.springframework.web.multipart.MultipartFile;

import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.Map;

@Service
@Slf4j
public class SpeechRecognitionService {

    private final ObjectMapper objectMapper;
    private Model model;


    public SpeechRecognitionService(ObjectMapper objectMapper) throws IOException {
        this.objectMapper = objectMapper;

        // Set up Vosk logging level
        LibVosk.setLogLevel(LogLevel.INFO);


        model = new Model("src/main/resources/models/vosk-model-en-in-0.5");
    }


    public String recognizeSpeech(MultipartFile audioFile) {
        if (model == null) {
            return "Speech recognition model is not available";
        }

        try {
            // Convert MultipartFile to AudioInputStream
            byte[] audioBytes = audioFile.getBytes();
            ByteArrayInputStream bais = new ByteArrayInputStream(audioBytes);
            AudioInputStream audioInputStream = AudioSystem.getAudioInputStream(bais);

            // Get audio format
            AudioFormat format = audioInputStream.getFormat();

            // Create recognizer
            Recognizer recognizer = new Recognizer(model, format.getSampleRate());

            // Process audio
            byte[] buffer = new byte[4096];
            int bytesRead;

            while ((bytesRead = audioInputStream.read(buffer)) != -1) {
                if (recognizer.acceptWaveForm(buffer, bytesRead)) {
                    // Partial result
                    log.debug("Partial result: {}", recognizer.getResult());
                }
            }

            // Get final result
            String result = recognizer.getFinalResult();
            recognizer.close();

            // Extract just the text from the JSON result
            Map<String, Object> resultMap = objectMapper.readValue(result, HashMap.class);
            String recognizedText = (String) resultMap.get("text");

            return recognizedText;

        } catch (Exception e) {
            log.error("Error during speech recognition", e);
            return "Error recognizing speech: " + e.getMessage();
        }
    }
}