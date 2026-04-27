package com.proconnect.proconnect.service;

import com.proconnect.proconnect.entity.cerezler;
import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.repository.cerezlerrepository;
import com.proconnect.proconnect.repository.kullanicirepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;

@Service
public class cerezlerservice {

    @Autowired
    private cerezlerrepository cerezlerRepository;

    @Autowired
    private kullanicirepository kullaniciRepository;

    public cerezler cerezOnayla(String eposta) {
        kullanici kullanici = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(
                HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"
            ));

        cerezler cerez = cerezlerRepository.findByKullanici(kullanici)
            .orElse(new cerezler());

        cerez.setKullanici(kullanici);
        cerez.setCerezOnay(true);
        cerez.setCerezTarihi(LocalDateTime.now());

        return cerezlerRepository.save(cerez);
    }

    public cerezler konumKaydet(String eposta, Double lat, Double lng) {
        kullanici kullanici = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(
                HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"
            ));

        cerezler cerez = cerezlerRepository.findByKullanici(kullanici)
            .orElseThrow(() -> new ResponseStatusException(
                HttpStatus.BAD_REQUEST, "Önce çerez onayı gerekli"
            ));

        cerez.setKonumIzni(true);
        cerez.setKonumLat(lat);
        cerez.setKonumLng(lng);
        cerez.setKonumGuncellenme(LocalDateTime.now());

        return cerezlerRepository.save(cerez);
    }
}
