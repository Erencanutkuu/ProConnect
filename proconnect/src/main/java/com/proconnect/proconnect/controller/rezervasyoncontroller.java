package com.proconnect.proconnect.controller;

import com.proconnect.proconnect.entity.rezervasyon;
import com.proconnect.proconnect.service.rezervasyonservice;
import com.proconnect.proconnect.util.jwtutil;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/rezervasyon")
public class rezervasyoncontroller {

    @Autowired
    private rezervasyonservice rezervasyonService;

    @Autowired
    private jwtutil jwtUtil;

    // POST /rezervasyon/olustur  body: {"ilanId": 1}
    @PostMapping("/olustur")
    public rezervasyon olustur(@CookieValue("jwt") String token, @RequestBody Map<String, Long> body) {
        String eposta = jwtUtil.extractUsername(token);
        return rezervasyonService.olustur(eposta, body.get("ilanId"));
    }

    // POST /rezervasyon/onayla  body: {"rezervasyonId": 1}
    @PostMapping("/onayla")
    public rezervasyon onayla(@CookieValue("jwt") String token, @RequestBody Map<String, Long> body) {
        String eposta = jwtUtil.extractUsername(token);
        return rezervasyonService.onayla(eposta, body.get("rezervasyonId"));
    }

    // POST /rezervasyon/tamamla  body: {"rezervasyonId": 1}
    @PostMapping("/tamamla")
    public rezervasyon tamamla(@CookieValue("jwt") String token, @RequestBody Map<String, Long> body) {
        String eposta = jwtUtil.extractUsername(token);
        return rezervasyonService.tamamla(eposta, body.get("rezervasyonId"));
    }

    // POST /rezervasyon/iptal  body: {"rezervasyonId": 1}
    @PostMapping("/iptal")
    public rezervasyon iptalEt(@CookieValue("jwt") String token, @RequestBody Map<String, Long> body) {
        String eposta = jwtUtil.extractUsername(token);
        return rezervasyonService.iptalEt(eposta, body.get("rezervasyonId"));
    }

    // GET /rezervasyon/benimkiler — Müşterinin rezervasyonları
    @GetMapping("/benimkiler")
    public List<rezervasyon> benimkiler(@CookieValue("jwt") String token) {
        String eposta = jwtUtil.extractUsername(token);
        return rezervasyonService.musteriRezervasyonlari(eposta);
    }

    // GET /rezervasyon/gelenler — Ustanın gelen rezervasyonları
    @GetMapping("/gelenler")
    public List<rezervasyon> gelenler(@CookieValue("jwt") String token) {
        String eposta = jwtUtil.extractUsername(token);
        return rezervasyonService.ustaRezervasyonlari(eposta);
    }
}
