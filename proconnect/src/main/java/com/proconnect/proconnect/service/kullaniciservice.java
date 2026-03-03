package com.proconnect.proconnect.service;

import com.proconnect.proconnect.dto.kaydol;
import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.entity.Rol;
import com.proconnect.proconnect.repository.kullanicirepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

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
        
        

        if(Rol.USTA.equals(request.getRol())) { // Eğer gelen rol USTA ise, yeni kaydı da USTA yap

            yeniKullanici.setRol(Rol.USTA);
            
            
        }
        else if(Rol.MUSTERI.equals(request.getRol())) { // Eğer gelen rol MÜŞTERİ ise, yeni kaydı da MÜŞTERİ yap
            yeniKullanici.setRol(Rol.MUSTERI);
        }

        return repository.save(yeniKullanici); // Ve depocuya (Repository) "Bunu rafa koy" diyoruz
    }
}