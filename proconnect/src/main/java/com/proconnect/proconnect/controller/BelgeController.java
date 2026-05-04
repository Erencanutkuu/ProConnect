package com.proconnect.proconnect.controller;

import com.proconnect.proconnect.service.BelgeService;
import com.proconnect.proconnect.util.jwtutil;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/")
public class BelgeController {

    @Autowired
    private BelgeService belgeService;

    @Autowired
    private jwtutil jwtUtil;

    @PostMapping("/belge-yukle")
    public Map<String, Object> belgeYukle(
            @CookieValue("jwt") String token,
            @RequestParam("dosya") MultipartFile dosya) {

        String eposta = jwtUtil.extractUsername(token);
        belgeService.belgeYukle(eposta, dosya);

        Map<String, Object> sonuc = new LinkedHashMap<>();
        sonuc.put("basarili", true);
        sonuc.put("mesaj", "Belge basariyla yuklendi. Basvurunuz inceleniyor.");
        return sonuc;
    }
}
