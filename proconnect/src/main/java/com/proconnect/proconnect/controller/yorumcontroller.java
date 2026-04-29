package com.proconnect.proconnect.controller;

import com.proconnect.proconnect.entity.yorum;
import com.proconnect.proconnect.service.yorumservice;
import com.proconnect.proconnect.util.jwtutil;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/yorum")
public class yorumcontroller {

    @Autowired
    private yorumservice yorumService;

    @Autowired
    private jwtutil jwtUtil;

    // POST /yorum/yaz  body: {"ilanId": 1, "puan": 5, "yorumMetni": "Harika hizmet"}
    @PostMapping("/yaz")
    public yorum yorumYaz(@CookieValue("jwt") String token, @RequestBody Map<String, Object> body) {
        String eposta = jwtUtil.extractUsername(token);
        Long ilanId = ((Number) body.get("ilanId")).longValue();
        Integer puan = ((Number) body.get("puan")).intValue();
        String yorumMetni = (String) body.get("yorumMetni");
        return yorumService.yorumYaz(eposta, ilanId, puan, yorumMetni);
    }

    // GET /yorum/ilan/1 — İlanın yorumları
    @GetMapping("/ilan/{ilanId}")
    public List<yorum> ilanYorumlari(@PathVariable Long ilanId) {
        return yorumService.ilanYorumlari(ilanId);
    }

    // GET /yorum/puan/1 — İlanın puan özeti
    @GetMapping("/puan/{ilanId}")
    public Map<String, Object> ilanPuanOzeti(@PathVariable Long ilanId) {
        return yorumService.ilanPuanOzeti(ilanId);
    }

    // GET /yorum/usta/1 — Ustanın genel puanı
    @GetMapping("/usta/{ustaId}")
    public Map<String, Object> ustaPuanOzeti(@PathVariable Long ustaId) {
        return yorumService.ustaPuanOzeti(ustaId);
    }
}
