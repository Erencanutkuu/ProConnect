package com.proconnect.proconnect.controller;

import com.proconnect.proconnect.entity.rezervasyon;
import com.proconnect.proconnect.service.rezervasyonservice;
import com.proconnect.proconnect.util.jwtutil;
import com.proconnect.proconnect.util.JwtResolver;

import jakarta.servlet.http.HttpServletRequest;
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

    private String resolveEposta(String cookieToken, HttpServletRequest request) {
        String token = cookieToken != null ? cookieToken : JwtResolver.resolveToken(request);
        return jwtUtil.extractUsername(token);
    }

    @PostMapping("/olustur")
    public rezervasyon olustur(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request,
            @RequestBody Map<String, Long> body) {
        return rezervasyonService.olustur(resolveEposta(cookieToken, request), body.get("ilanId"));
    }

    @PostMapping("/onayla")
    public rezervasyon onayla(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request,
            @RequestBody Map<String, Long> body) {
        return rezervasyonService.onayla(resolveEposta(cookieToken, request), body.get("rezervasyonId"));
    }

    @PostMapping("/tamamla")
    public rezervasyon tamamla(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request,
            @RequestBody Map<String, Long> body) {
        return rezervasyonService.tamamla(resolveEposta(cookieToken, request), body.get("rezervasyonId"));
    }

    @PostMapping("/iptal")
    public rezervasyon iptalEt(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request,
            @RequestBody Map<String, Long> body) {
        return rezervasyonService.iptalEt(resolveEposta(cookieToken, request), body.get("rezervasyonId"));
    }

    @GetMapping("/benimkiler")
    public List<rezervasyon> benimkiler(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request) {
        return rezervasyonService.musteriRezervasyonlari(resolveEposta(cookieToken, request));
    }

    @GetMapping("/gelenler")
    public List<rezervasyon> gelenler(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request) {
        return rezervasyonService.ustaRezervasyonlari(resolveEposta(cookieToken, request));
    }
}
