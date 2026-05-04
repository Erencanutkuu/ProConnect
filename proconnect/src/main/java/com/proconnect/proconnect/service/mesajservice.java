package com.proconnect.proconnect.service;

import com.proconnect.proconnect.entity.ilanlar;
import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.entity.mesaj;
import com.proconnect.proconnect.repository.ilanlarrepository;
import com.proconnect.proconnect.repository.kullanicirepository;
import com.proconnect.proconnect.repository.mesajrepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.*;

@Service
public class mesajservice {

    @Autowired
    private mesajrepository mesajRepository;

    @Autowired
    private kullanicirepository kullaniciRepository;

    @Autowired
    private ilanlarrepository ilanlarRepository;

    // Mesaj gönder
    public mesaj mesajGonder(String gonderenEposta, Long aliciId, Long ilanId, String mesajMetni) {
        kullanici gonderen = kullaniciRepository.findByEposta(gonderenEposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Gönderen bulunamadı"));

        kullanici alici = kullaniciRepository.findById(aliciId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Alıcı bulunamadı"));

        if (gonderen.getId().equals(alici.getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Kendinize mesaj gönderemezsiniz");
        }

        if (mesajMetni == null || mesajMetni.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mesaj boş olamaz");
        }

        mesaj m = new mesaj();
        m.setGonderen(gonderen);
        m.setAlici(alici);
        m.setMesajMetni(mesajMetni);

        if (ilanId != null) {
            ilanlar ilan = ilanlarRepository.findById(ilanId).orElse(null);
            m.setIlan(ilan);
        }

        return mesajRepository.save(m);
    }

    // Konuşma listesi (partner + son mesaj + okunmamış sayısı)
    public List<Map<String, Object>> konusmalar(String eposta) {
        kullanici ben = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));

        List<Long> partnerIds = mesajRepository.konusmaPartnerleri(ben.getId());
        List<Map<String, Object>> sonuc = new ArrayList<>();

        for (Long partnerId : partnerIds) {
            kullanici partner = kullaniciRepository.findById(partnerId).orElse(null);
            if (partner == null) continue;

            mesaj son = mesajRepository.sonMesaj(ben.getId(), partnerId);
            long okunmamis = mesajRepository.okunmamisSayisiPartner(ben.getId(), partnerId);

            Map<String, Object> konusma = new LinkedHashMap<>();
            konusma.put("partnerId", partner.getId());
            konusma.put("partnerAd", partner.getAd() + " " + partner.getSoyad());
            konusma.put("partnerRol", partner.getRol().name());
            if (son != null) {
                konusma.put("sonMesaj", son.getMesajMetni());
                konusma.put("sonMesajTarih", son.getTarih());
                konusma.put("sonMesajBendenMi", son.getGonderen().getId().equals(ben.getId()));
            }
            konusma.put("okunmamis", okunmamis);
            sonuc.add(konusma);
        }

        // Son mesaj tarihine göre sırala (en yeni en üstte)
        sonuc.sort((a, b) -> {
            Object ta = a.get("sonMesajTarih");
            Object tb = b.get("sonMesajTarih");
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return tb.toString().compareTo(ta.toString());
        });

        return sonuc;
    }

    // Mesajları getir + okundu işaretle
    public List<mesaj> mesajlariGetir(String eposta, Long partnerId) {
        kullanici ben = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));

        // Partnerden gelen mesajları okundu yap
        mesajRepository.okunduIsaretle(ben.getId(), partnerId);

        return mesajRepository.mesajlarArasinda(ben.getId(), partnerId);
    }

    // Okunmamış mesaj sayısı
    public long okunmamisSayisi(String eposta) {
        kullanici ben = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));
        return mesajRepository.toplamOkunmamis(ben.getId());
    }
}
