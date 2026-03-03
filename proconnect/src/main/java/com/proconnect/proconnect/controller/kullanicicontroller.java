package com.proconnect.proconnect.controller;

import com.proconnect.proconnect.dto.kaydol;
import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.service.kullaniciservice;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController // Bu sınıfın dış dünyaya kapı olduğunu söyler
@RequestMapping("/") // İŞTE BURASI! Başına hiçbir şey (api/v1 gibi) yazmadık.
public class kullanicicontroller {

    @Autowired // Spring'e "Bu servisi kullanacağım, lütfen hazırla" demek
    private kullaniciservice service;

    @PostMapping("kaydol") // Adresimiz artık: localhost:8080/kaydol
    public kullanici kaydol(@RequestBody kaydol request) {  // verileri çekmek için
        return service.kullaniciKaydet(request); // Müşteri olarak kaydet
    }
}