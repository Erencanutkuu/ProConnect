package com.proconnect.proconnect.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.repository.kullanicirepository;
import com.proconnect.proconnect.util.jwtutil;

@Service
public class loginservice {

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private kullanicirepository repository;

    @Autowired
    private jwtutil jwtUtil;  // ← bunu ekle

    public String login(String eposta, String sifre) {
        
        // 1. Kullanıcıyı bul
        kullanici kullanici = repository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(
                HttpStatus.UNAUTHORIZED, "Geçersiz eposta veya şifre"
            ));

        // 2. Şifreyi kontrol et
        if (!passwordEncoder.matches(sifre, kullanici.getSifreHash())) {
            throw new ResponseStatusException(
                HttpStatus.UNAUTHORIZED, "Geçersiz eposta veya şifre"
            );
        }

        // 3. Token üret ve döndür
        return jwtUtil.generateToken(
            kullanici.getEposta(),
            kullanici.getRol().name()
        );
    }
}