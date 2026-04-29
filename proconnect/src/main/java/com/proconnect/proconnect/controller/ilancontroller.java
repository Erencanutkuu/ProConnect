package com.proconnect.proconnect.controller;

import com.proconnect.proconnect.entity.ilanlar;
import com.proconnect.proconnect.service.ilanservice;
import com.proconnect.proconnect.util.jwtutil;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/ilan")
public class ilancontroller {

    @Autowired
    private ilanservice ilanService;

    @Autowired
    private jwtutil jwtUtil;

    @PostMapping("/olustur")
    public ilanlar olustur(@CookieValue("jwt") String token, @RequestBody Map<String, Object> body) {
        String eposta = jwtUtil.extractUsername(token);
        return ilanService.olustur(
            eposta,
            (String) body.get("baslik"),
            (String) body.get("aciklama"),
            body.get("butce") != null ? new BigDecimal(body.get("butce").toString()) : null,
            (String) body.get("sehir"),
            (String) body.get("ilce"),
            body.get("konumLat") != null ? ((Number) body.get("konumLat")).doubleValue() : null,
            body.get("konumLng") != null ? ((Number) body.get("konumLng")).doubleValue() : null
        );
    }

    @GetMapping("/aktif")
    public List<ilanlar> aktifIlanlar(
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng,
            @RequestParam(required = false) String sehir) {
        return ilanService.aktifIlanlar(lat, lng, sehir);
    }

    @GetMapping("/benimkiler")
    public List<ilanlar> benimkiler(@CookieValue("jwt") String token) {
        String eposta = jwtUtil.extractUsername(token);
        return ilanService.benimIlanlarim(eposta);
    }
}
