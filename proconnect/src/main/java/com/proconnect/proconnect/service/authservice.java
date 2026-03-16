package com.proconnect.proconnect.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;

import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.repository.kullanicirepository;
import com.proconnect.proconnect.util.tcno;



@Service
@RequiredArgsConstructor
public class authservice {
    private final kullanicirepository kullanicirepository;
    private final PasswordEncoder passwordEncoder;



    public String register(String ad, String soyad, String eposta, String sifre, String tcno) {
        // Eposta zaten var mı kontrol et
        if (kullanicirepository.existsByEposta(eposta)) {
            return "Bu eposta zaten kayıtlı.";
        }

        // Şifreyi hash'le
        String sifreHash = passwordEncoder.encode(sifre);

        // Yeni kullanıcı oluştur ve kaydet
        kullanici yeniKullanici = new kullanici();
        yeniKullanici.setAd(ad);
        yeniKullanici.setSoyad(soyad);
        yeniKullanici.setEposta(eposta);
        yeniKullanici.setSifreHash(sifreHash);
        yeniKullanici.setTcno(new tcno(tcno)); // tcno sınıfını kullanarak tcno'yu oluştur
        kullanicirepository.save(yeniKullanici);

        return "Kayıt başarılı!";
    }

}
