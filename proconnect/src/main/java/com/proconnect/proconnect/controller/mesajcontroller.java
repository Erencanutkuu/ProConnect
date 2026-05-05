package com.proconnect.proconnect.controller;

import com.proconnect.proconnect.entity.mesaj;
import com.proconnect.proconnect.service.mesajservice;
import com.proconnect.proconnect.util.jwtutil;
import com.proconnect.proconnect.util.JwtResolver;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/mesaj")
public class mesajcontroller {

    @Autowired
    private mesajservice mesajService;

    @Autowired
    private jwtutil jwtUtil;

    @PostMapping("/gonder")
    public Map<String, Object> gonder(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request,
            @RequestBody Map<String, Object> body) {
        String token = cookieToken != null ? cookieToken : JwtResolver.resolveToken(request);
        String eposta = jwtUtil.extractUsername(token);

        Long aliciId = Long.valueOf(body.get("aliciId").toString());
        Long ilanId = body.get("ilanId") != null ? Long.valueOf(body.get("ilanId").toString()) : null;
        String mesajMetni = (String) body.get("mesajMetni");

        mesaj m = mesajService.mesajGonder(eposta, aliciId, ilanId, mesajMetni);

        Map<String, Object> sonuc = new LinkedHashMap<>();
        sonuc.put("basarili", true);
        sonuc.put("mesajId", m.getId());
        return sonuc;
    }

    @GetMapping("/konusmalar")
    public List<Map<String, Object>> konusmalar(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request) {
        String token = cookieToken != null ? cookieToken : JwtResolver.resolveToken(request);
        String eposta = jwtUtil.extractUsername(token);
        return mesajService.konusmalar(eposta);
    }

    @GetMapping("/oku/{partnerId}")
    public List<mesaj> oku(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request,
            @PathVariable("partnerId") Long partnerId) {
        String token = cookieToken != null ? cookieToken : JwtResolver.resolveToken(request);
        String eposta = jwtUtil.extractUsername(token);
        return mesajService.mesajlariGetir(eposta, partnerId);
    }

    @GetMapping("/okunmamis-sayisi")
    public Map<String, Object> okunmamisSayisi(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request) {
        String token = cookieToken != null ? cookieToken : JwtResolver.resolveToken(request);
        String eposta = jwtUtil.extractUsername(token);
        long sayi = mesajService.okunmamisSayisi(eposta);

        Map<String, Object> sonuc = new LinkedHashMap<>();
        sonuc.put("sayi", sayi);
        return sonuc;
    }
}
