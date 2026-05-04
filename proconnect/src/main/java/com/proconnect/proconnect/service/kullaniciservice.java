package com.proconnect.proconnect.service;

import com.proconnect.proconnect.dto.kaydol;
import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.entity.Rol;
import com.proconnect.proconnect.repository.kullanicirepository;
import com.proconnect.proconnect.util.tcno;

import org.springframework.http.HttpStatus;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

@Service // Bu işaret, bu sınıfın projenin "Karar Merkezi" (Aşçısı) olduğunu söyler
public class kullaniciservice {

    @Autowired
    private kullanicirepository repository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private EpostaService epostaService;

    // Garsonun getirdiği siparişi (DTO) alıp, veritabanına uygun (Entity) hale getiren metod
    public kullanici kullaniciKaydet(kaydol request ) {   // burda kaydolmadan request adını çekiyoruz ve kullanıyoruz
        kullanici yeniKullanici = new kullanici();
        yeniKullanici.setAd(request.getAd());
        yeniKullanici.setSoyad(request.getSoyad());
        yeniKullanici.setEposta(request.getEposta());
        yeniKullanici.setTelefon(request.getTelefon());
        
        // Şifreyi bcrypt ile hashleyip sakla
        yeniKullanici.setSifreHash(passwordEncoder.encode(request.getSifre()));
        
        if (request.getRol() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Rol boş bırakılamaz");
        }

        yeniKullanici.setRol(request.getRol());

        if (Rol.USTA.equals(request.getRol())) {
            if (!StringUtils.hasText(request.getTcno())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "TC Kimlik numarası zorunludur");
            }
            if (!tcno.validate(request.getTcno())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "TC Kimlik numarası geçersiz");
            }
            yeniKullanici.setTcno(new tcno(request.getTcno()));
        }

        kullanici kaydedilen = repository.save(yeniKullanici);

        // Kayit sonrasi e-posta dogrulama kodu gonder
        try {
            epostaService.dogrulamaKoduGonder(kaydedilen);
        } catch (Exception e) {
            // Mail gonderilemezse kaydi iptal etme, kullanici tekrar kod isteyebilir
        }

        return kaydedilen;
    }

    // Profil güncelle (ad, soyad, telefon)
    public kullanici profilGuncelle(String eposta, String ad, String soyad, String telefon) {
        kullanici k = repository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));

        if (StringUtils.hasText(ad)) k.setAd(ad);
        if (StringUtils.hasText(soyad)) k.setSoyad(soyad);
        if (telefon != null) k.setTelefon(telefon);

        return repository.save(k);
    }

    // Şifre değiştir
    public void sifreDegistir(String eposta, String mevcutSifre, String yeniSifre) {
        kullanici k = repository.findByEposta(eposta)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı"));

        if (!passwordEncoder.matches(mevcutSifre, k.getSifreHash())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mevcut şifre hatalı");
        }

        if (yeniSifre == null || yeniSifre.length() < 6) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Yeni şifre en az 6 karakter olmalıdır");
        }

        k.setSifreHash(passwordEncoder.encode(yeniSifre));
        repository.save(k);
    }

}
