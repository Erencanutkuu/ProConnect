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
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

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

        if (!Boolean.TRUE.equals(usta.getEpostaDogrulandi())) {
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

    // Ilan sil (sadece kendi ilani)
    public void ilanSil(String eposta, Long ilanId) {
        kullanici usta = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));

        ilanlar ilan = ilanlarRepository.findById(ilanId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "İlan bulunamadı"));

        if (!ilan.getOlusturanKullanici().getId().equals(usta.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Sadece kendi ilanınızı silebilirsiniz");
        }

        ilanlarRepository.delete(ilan);
    }

    // Ustanın kendi ilanları
    public List<ilanlar> benimIlanlarim(String eposta) {
        kullanici usta = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));
        return ilanlarRepository.findByOlusturanKullaniciId(usta.getId());
    }

    // İlan güncelle (sadece kendi ilanı)
    public ilanlar ilanGuncelle(String eposta, Long ilanId, String baslik, String aciklama,
                                BigDecimal butce, String sehir, String ilce) {
        kullanici usta = kullaniciRepository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));

        ilanlar ilan = ilanlarRepository.findById(ilanId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "İlan bulunamadı"));

        if (!ilan.getOlusturanKullanici().getId().equals(usta.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Sadece kendi ilanınızı güncelleyebilirsiniz");
        }

        if (baslik != null && !baslik.isBlank()) ilan.setBaslik(baslik);
        if (aciklama != null && !aciklama.isBlank()) ilan.setAciklama(aciklama);
        if (butce != null) ilan.setButce(butce);
        if (sehir != null) ilan.setSehir(sehir);
        if (ilce != null) ilan.setIlce(ilce);

        return ilanlarRepository.save(ilan);
    }

    // Fiyat önerisi: benzer ilanları analiz et
    public Map<String, Object> fiyatOnerisi(String baslik) {
        Map<String, Object> sonuc = new LinkedHashMap<>();

        // Başlıktaki kelimeleri ayır ve her biri ile benzer ilanları ara
        String[] kelimeler = baslik.trim().toLowerCase().split("\\s+");
        List<ilanlar> tumBenzerler = new java.util.ArrayList<>();

        for (String kelime : kelimeler) {
            if (kelime.length() >= 3) { // 3 harften kısa kelimeleri atla
                List<ilanlar> bulunanlar = ilanlarRepository.benzerIlanlarButceli(kelime);
                tumBenzerler.addAll(bulunanlar);
            }
        }

        // Tekrar edenleri kaldır
        List<ilanlar> benzersiz = tumBenzerler.stream()
            .collect(Collectors.toMap(ilanlar::getId, i -> i, (a, b) -> a))
            .values().stream().toList();

        List<BigDecimal> fiyatlar = benzersiz.stream()
            .map(ilanlar::getButce)
            .filter(b -> b != null && b.compareTo(BigDecimal.ZERO) > 0)
            .toList();

        if (fiyatlar.isEmpty()) {
            sonuc.put("oneri", false);
            sonuc.put("mesaj", "Benzer ilan bulunamadı, fiyatı kendiniz belirleyin.");
            return sonuc;
        }

        BigDecimal toplam = fiyatlar.stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal ortalama = toplam.divide(BigDecimal.valueOf(fiyatlar.size()), 0, RoundingMode.HALF_UP);
        BigDecimal min = fiyatlar.stream().min(BigDecimal::compareTo).orElse(BigDecimal.ZERO);
        BigDecimal max = fiyatlar.stream().max(BigDecimal::compareTo).orElse(BigDecimal.ZERO);

        sonuc.put("oneri", true);
        sonuc.put("ortalama", ortalama);
        sonuc.put("min", min);
        sonuc.put("max", max);
        sonuc.put("ilanSayisi", fiyatlar.size());
        sonuc.put("mesaj", fiyatlar.size() + " benzer ilan analiz edildi.");

        return sonuc;
    }
}
