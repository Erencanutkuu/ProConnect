package com.proconnect.proconnect.service;

import com.proconnect.proconnect.entity.RezervasyonDurum;
import com.proconnect.proconnect.entity.Rol;
import com.proconnect.proconnect.entity.ilanlar;
import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.entity.rezervasyon;
import com.proconnect.proconnect.repository.ilanlarrepository;
import com.proconnect.proconnect.repository.kullanicirepository;
import com.proconnect.proconnect.repository.rezervasyonrepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class rezervasyonservice {

    @Autowired
    private rezervasyonrepository rezervasyonRepository;

    @Autowired
    private kullanicirepository kullaniciRepository;

    @Autowired
    private ilanlarrepository ilanlarRepository;

    // Rezervasyon oluştur (müşteri yapar)
    public rezervasyon olustur(String eposta, Long ilanId) {
        kullanici musteri = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));

        if (musteri.getRol() != Rol.MUSTERI) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Sadece müşteriler rezervasyon yapabilir");
        }

        ilanlar ilan = ilanlarRepository.findById(ilanId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "İlan bulunamadı"));

        if (rezervasyonRepository.existsByMusteriIdAndIlanIdAndDurumNot(musteri.getId(), ilanId, RezervasyonDurum.IPTAL)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Bu ilana zaten rezervasyon yaptınız");
        }

        rezervasyon rez = new rezervasyon();
        rez.setMusteri(musteri);
        rez.setIlan(ilan);

        return rezervasyonRepository.save(rez);
    }

    // Onayla (usta yapar)
    public rezervasyon onayla(String eposta, Long rezervasyonId) {
        kullanici usta = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));

        rezervasyon rez = rezervasyonRepository.findById(rezervasyonId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Rezervasyon bulunamadı"));

        if (!rez.getIlan().getOlusturanKullanici().getId().equals(usta.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bu rezervasyonu onaylama yetkiniz yok");
        }

        if (rez.getDurum() != RezervasyonDurum.BEKLEMEDE) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Sadece beklemedeki rezervasyonlar onaylanabilir");
        }

        rez.setDurum(RezervasyonDurum.ONAYLANDI);
        return rezervasyonRepository.save(rez);
    }

    // Tamamla (usta yapar)
    public rezervasyon tamamla(String eposta, Long rezervasyonId) {
        kullanici usta = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));

        rezervasyon rez = rezervasyonRepository.findById(rezervasyonId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Rezervasyon bulunamadı"));

        if (!rez.getIlan().getOlusturanKullanici().getId().equals(usta.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bu rezervasyonu tamamlama yetkiniz yok");
        }

        if (rez.getDurum() != RezervasyonDurum.ONAYLANDI) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Sadece onaylanmış rezervasyonlar tamamlanabilir");
        }

        rez.setDurum(RezervasyonDurum.TAMAMLANDI);
        rez.setTamamlanmaTarihi(LocalDateTime.now());
        return rezervasyonRepository.save(rez);
    }

    // İptal et (müşteri veya usta yapabilir)
    public rezervasyon iptalEt(String eposta, Long rezervasyonId) {
        kullanici kullanici = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));

        rezervasyon rez = rezervasyonRepository.findById(rezervasyonId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Rezervasyon bulunamadı"));

        boolean musteriMi = rez.getMusteri().getId().equals(kullanici.getId());
        boolean ustaMi = rez.getIlan().getOlusturanKullanici().getId().equals(kullanici.getId());

        if (!musteriMi && !ustaMi) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bu rezervasyonu iptal etme yetkiniz yok");
        }

        if (rez.getDurum() == RezervasyonDurum.TAMAMLANDI || rez.getDurum() == RezervasyonDurum.IPTAL) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Bu rezervasyon iptal edilemez");
        }

        rez.setDurum(RezervasyonDurum.IPTAL);
        return rezervasyonRepository.save(rez);
    }

    // Müşterinin rezervasyonları
    public List<rezervasyon> musteriRezervasyonlari(String eposta) {
        kullanici musteri = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));
        return rezervasyonRepository.findByMusteriId(musteri.getId());
    }

    // Ustanın gelen rezervasyonları
    public List<rezervasyon> ustaRezervasyonlari(String eposta) {
        kullanici usta = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));
        return rezervasyonRepository.findByIlanOlusturanKullaniciId(usta.getId());
    }
}
