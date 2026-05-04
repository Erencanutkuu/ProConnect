package com.proconnect.proconnect.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.UUID;

@Service
public class GorselService {

    @Value("${openai.api.key}")
    private String openaiApiKey;

    private final ObjectMapper mapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    /**
     * Baslik ve aciklamaya uygun AI gorsel uretir, uploads klasorune kaydeder.
     * Hata durumunda null doner.
     */
    public String gorselUret(String baslik, String aciklama) {
        try {
            // 1. Prompt olustur
            String prompt = "Professional, clean service advertisement image for: " + baslik + ". " + aciklama;
            if (prompt.length() > 1000) {
                prompt = prompt.substring(0, 1000);
            }

            // 2. DALL-E 3 API'ye istek at
            String requestBody = mapper.writeValueAsString(Map.of(
                "model", "dall-e-3",
                "prompt", prompt,
                "n", 1,
                "size", "1024x1024"
            ));

            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("https://api.openai.com/v1/images/generations"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + openaiApiKey)
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            JsonNode root = mapper.readTree(response.body());
            String imageUrl = root.get("data").get(0).get("url").asText();

            // 3. Gorseli indir
            HttpRequest downloadRequest = HttpRequest.newBuilder()
                .uri(URI.create(imageUrl))
                .GET()
                .build();

            HttpResponse<InputStream> imageResponse = httpClient.send(downloadRequest, HttpResponse.BodyHandlers.ofInputStream());

            // 4. uploads klasorune kaydet
            String uploadsDir = "src/main/resources/static/uploads/";
            Path uploadPath = Paths.get(uploadsDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            String fileName = UUID.randomUUID().toString() + ".png";
            Path filePath = uploadPath.resolve(fileName);
            Files.copy(imageResponse.body(), filePath, StandardCopyOption.REPLACE_EXISTING);

            return fileName;

        } catch (Exception e) {
            // Hata durumunda null don, ilan resimsiz olusur
            System.out.println("GorselService HATA: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }
}
