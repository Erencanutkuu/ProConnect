package com.proconnect.proconnect.service;

import com.proconnect.proconnect.entity.RezervasyonDurum;
import com.proconnect.proconnect.entity.ilanlar;
import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.entity.yorum;
import com.proconnect.proconnect.repository.ilanlarrepository;
import com.proconnect.proconnect.repository.kullanicirepository;
import com.proconnect.proconnect.repository.rezervasyonrepository;
import com.proconnect.proconnect.repository.yorumrepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class yorumservice {

    @Autowired
    private yorumrepository yorumRepository;

    @Autowired
    private kullanicirepository kullaniciRepository;

    @Autowired
    private ilanlarrepository ilanlarRepository;

    @Autowired
    private rezervasyonrepository rezervasyonRepository;

    // Yorum yaz (sadece tamamlanmış rezervasyonu olan müşteri yazabilir)
    public yorum yorumYaz(String eposta, Long ilanId, Integer puan, String yorumMetni) {
        kullanici musteri = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));

        ilanlar ilan = ilanlarRepository.findById(ilanId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "İlan bulunamadı"));

        // Tamamlanmış rezervasyonu var mı kontrol et
        boolean tamamlanmis = rezervasyonRepository.findByMusteriId(musteri.getId()).stream()
            .anyMatch(r -> r.getIlan().getId().equals(ilanId) && r.getDurum() == RezervasyonDurum.TAMAMLANDI);

        if (!tamamlanmis) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Yorum yapabilmek için tamamlanmış bir rezervasyonunuz olmalı");
        }

        // Aynı ilana tekrar yorum engeli
        if (yorumRepository.existsByMusteriIdAndIlanId(musteri.getId(), ilanId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Bu ilana zaten yorum yaptınız");
        }

        if (puan < 1 || puan > 5) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Puan 1 ile 5 arasında olmalı");
        }

        yorum yeniYorum = new yorum();
        yeniYorum.setMusteri(musteri);
        yeniYorum.setIlan(ilan);
        yeniYorum.setPuan(puan);
        yeniYorum.setYorumMetni(yorumMetni);

        return yorumRepository.save(yeniYorum);
    }

    // İlanın yorumlarını getir
    public List<yorum> ilanYorumlari(Long ilanId) {
        return yorumRepository.findByIlanId(ilanId);
    }

    // İlanın puan özeti (ortalama + yorum sayısı)
    public Map<String, Object> ilanPuanOzeti(Long ilanId) {
        Double ortalama = yorumRepository.ortalamaByIlanId(ilanId);
        long yorumSayisi = yorumRepository.countByIlanId(ilanId);

        Map<String, Object> ozet = new LinkedHashMap<>();
        ozet.put("ortalama", ortalama != null ? Math.round(ortalama * 10.0) / 10.0 : 0);
        ozet.put("yorumSayisi", yorumSayisi);
        return ozet;
    }

    // Ustanın genel puan özeti
    public Map<String, Object> ustaPuanOzeti(Long ustaId) {
        Double ortalama = yorumRepository.ortalamaByUstaId(ustaId);

        Map<String, Object> ozet = new LinkedHashMap<>();
        ozet.put("ortalama", ortalama != null ? Math.round(ortalama * 10.0) / 10.0 : 0);
        return ozet;
    }
}
