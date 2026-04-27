package com.proconnect.proconnect.controller;

import com.proconnect.proconnect.entity.cerezler;
import com.proconnect.proconnect.service.cerezlerservice;
import com.proconnect.proconnect.util.jwtutil;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
public class cerezlercontroller {

    @Autowired
    private cerezlerservice cerezlerService;

    @Autowired
    private jwtutil jwtUtil;

    @PostMapping("/cerez-onay")
    public cerezler cerezOnayla(@CookieValue("jwt") String token) {
        String eposta = jwtUtil.extractUsername(token);
        return cerezlerService.cerezOnayla(eposta);
    }

    @PostMapping("/konum")
    public cerezler konumKaydet(
            @CookieValue("jwt") String token,
            @RequestBody Map<String, Double> body) {
        String eposta = jwtUtil.extractUsername(token);
        return cerezlerService.konumKaydet(eposta, body.get("lat"), body.get("lng"));
    }
}
