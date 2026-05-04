package com.proconnect.proconnect.service;

import com.proconnect.proconnect.entity.Rol;
import com.proconnect.proconnect.entity.ilanlar;
import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.repository.ilanlarrepository;
import com.proconnect.proconnect.repository.kullanicirepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

@Service
public class ilanservice {

    @Autowired
    private ilanlarrepository ilanlarRepository;

    @Autowired
    private kullanicirepository kullaniciRepository;

    // İlan oluştur (sadece usta)
    public ilanlar olustur(String eposta, String baslik, String aciklama,
                           BigDecimal butce, String sehir, String ilce,
                           Double konumLat, Double konumLng, String gorselYolu) {

        kullanici usta = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));

        if (usta.getRol() != Rol.USTA) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Sadece ustalar ilan oluşturabilir");
        }

        if (!usta.isEpostaDogrulandi()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Ilan olusturmak icin e-postanizi dogrulayin");
        }

        if (usta.getBelgeYolu() == null || usta.getBelgeYolu().isBlank()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Ilan olusturmak icin belgenizi yukleyin");
        }

        ilanlar ilan = new ilanlar();
        ilan.setBaslik(baslik);
        ilan.setAciklama(aciklama);
        ilan.setButce(butce);
        ilan.setSehir(sehir);
        ilan.setIlce(ilce);
        ilan.setKonumLat(konumLat);
        ilan.setKonumLng(konumLng);
        ilan.setOlusturanKullanici(usta);
        ilan.setIlanTarihi(LocalDateTime.now());
        ilan.setGorselYolu(gorselYolu);

        return ilanlarRepository.save(ilan);
    }

    // Tüm açık ilanları getir (şehir/konum varsa yakınlığa göre sırala)
    public List<ilanlar> aktifIlanlar(Double userLat, Double userLng, String userSehir) {
        List<ilanlar> liste = ilanlarRepository.tumAktifIlanlar();

        if (userSehir != null && !userSehir.isEmpty()) {
            // Aynı şehirdekileri öne al
            String sehirLower = userSehir.toLowerCase();
            liste.sort(Comparator.comparingInt((ilanlar ilan) -> {
                String ilanSehir = ilan.getSehir();
                if (ilanSehir != null && ilanSehir.toLowerCase().contains(sehirLower)) return 0;
                return 1;
            }).thenComparingDouble(ilan ->
                mesafeHesapla(userLat, userLng, ilan.getKonumLat(), ilan.getKonumLng())
            ));
        } else if (userLat != null && userLng != null) {
            liste.sort(Comparator.comparingDouble(ilan ->
                mesafeHesapla(userLat, userLng, ilan.getKonumLat(), ilan.getKonumLng())
            ));
        }

        return liste;
    }

    // Haversine mesafe hesaplama (km)
    private double mesafeHesapla(double lat1, double lng1, Double lat2, Double lng2) {
        if (lat2 == null || lng2 == null) return Double.MAX_VALUE;
        double R = 6371;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                   Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    // Ustanın kendi ilanları
    public List<ilanlar> benimIlanlarim(String eposta) {
        kullanici usta = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));
        return ilanlarRepository.findByOlusturanKullaniciId(usta.getId());
    }
}
