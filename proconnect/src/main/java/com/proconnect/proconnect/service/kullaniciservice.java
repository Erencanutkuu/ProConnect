package com.proconnect.proconnect.service;

import com.proconnect.proconnect.dto.kaydol;
import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.entity.Rol;
import com.proconnect.proconnect.repository.kullanicirepository;
import com.proconnect.util.tcno;
import org.springframework.http.HttpStatus;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

@Service // Bu işaret, bu sınıfın projenin "Karar Merkezi" (Aşçısı) olduğunu söyler
public class kullaniciservice {

    @Autowired // Bu işaret, veritabanı deposuna (Repository) giden kablodur
    private kullanicirepository repository;

    // Garsonun getirdiği siparişi (DTO) alıp, veritabanına uygun (Entity) hale getiren metod
    public kullanici kullaniciKaydet(kaydol request ) {   // burda kaydolmadan request adını çekiyoruz ve kullanıyoruz
        kullanici yeniKullanici = new kullanici();
        yeniKullanici.setAd(request.getAd());
        yeniKullanici.setSoyad(request.getSoyad());
        yeniKullanici.setEposta(request.getEposta());
        
        // Şimdilik ham şifreyi yazıyoruz, ilerde buraya şifreleme gelecek
        yeniKullanici.setSifreHash(request.getSifre()); 
        
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

        return repository.save(yeniKullanici); // Ve depocuya (Repository) "Bunu rafa koy" diyoruz
    }
}
