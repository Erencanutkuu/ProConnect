package com.proconnect.proconnect.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.proconnect.proconnect.entity.ilanlar;
import com.proconnect.proconnect.repository.ilanlarrepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

@Service
public class aramaservice {

    @Autowired
    private ilanlarrepository ilanlarRepository;

    @Value("${openai.api.key}")
    private String openaiApiKey;

    private final ObjectMapper mapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    // Ana arama metodu
    public Map<String, Object> ara(String query, Double userLat, Double userLng) throws Exception {

        // 1. OpenAI'a kullanıcının yazdığını gönder, niyetini anla
        Map<String, String> aiSonuc = openaiIleAnaliz(query);
        String kategori = aiSonuc.get("kategori");
        String sehir = aiSonuc.get("sehir");
        String oneri = aiSonuc.get("oneri");

        // 2. Veritabanında ara
        List<ilanlar> sonuclar;
        if (sehir != null && !sehir.isEmpty()) {
            sonuclar = ilanlarRepository.aramaSehirIle(kategori, sehir);
        } else {
            sonuclar = ilanlarRepository.aramaYap(kategori);
        }

        // 3. Kullanıcı konumu varsa yakınlığa göre sırala
        if (userLat != null && userLng != null) {
            sonuclar.sort(Comparator.comparingDouble(ilan ->
                mesafeHesapla(userLat, userLng, ilan.getKonumLat(), ilan.getKonumLng())
            ));
        }

        return Map.of(
            "aiOneri", oneri,
            "sonuclar", sonuclar
        );
    }

    // OpenAI'a sorgu gönder, niyeti anla
    private Map<String, String> openaiIleAnaliz(String query) throws Exception {
        String systemPrompt = "Sen bir hizmet arama asistanısın. Kullanıcının yazdığından " +
            "şu bilgileri JSON olarak çıkar: " +
            "{\"kategori\": \"hizmet türü\", \"sehir\": \"şehir adı veya boş\", \"oneri\": \"kullanıcıya kısa öneri\"}. " +
            "Sadece JSON döndür, başka bir şey yazma.";

        String requestBody = mapper.writeValueAsString(Map.of(
            "model", "gpt-4o-mini",
            "messages", List.of(
                Map.of("role", "system", "content", systemPrompt),
                Map.of("role", "user", "content", query)
            ),
            "temperature", 0.3
        ));

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create("https://api.openai.com/v1/chat/completions"))
            .header("Content-Type", "application/json")
            .header("Authorization", "Bearer " + openaiApiKey)
            .POST(HttpRequest.BodyPublishers.ofString(requestBody))
            .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        JsonNode root = mapper.readTree(response.body());
        String content = root.get("choices").get(0).get("message").get("content").asText();

        // JSON parse et
        content = content.replaceAll("```json", "").replaceAll("```", "").trim();
        JsonNode result = mapper.readTree(content);

        return Map.of(
            "kategori", result.has("kategori") ? result.get("kategori").asText() : query,
            "sehir", result.has("sehir") ? result.get("sehir").asText() : "",
            "oneri", result.has("oneri") ? result.get("oneri").asText() : ""
        );
    }

    // İki koordinat arası mesafe (km) - Haversine formülü
    private double mesafeHesapla(Double lat1, Double lng1, Double lat2, Double lng2) {
        if (lat2 == null || lng2 == null) return Double.MAX_VALUE;
        double R = 6371;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                   Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}
