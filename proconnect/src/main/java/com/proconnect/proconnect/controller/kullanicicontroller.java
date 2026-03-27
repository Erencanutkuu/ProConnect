package com.proconnect.proconnect.controller;

import com.proconnect.proconnect.dto.kaydol;
import com.proconnect.proconnect.dto.login;
import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.service.kullaniciservice;

import jakarta.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import com.proconnect.proconnect.service.loginservice;


@RestController // Bu sınıfın dış dünyaya kapı olduğunu söyler  // api vb işlemlerini burda yaparız 
@RequestMapping("/") // İŞTE BURASI! Başına hiçbir şey (api/v1 gibi) yazmadık.
public class kullanicicontroller {

    @Autowired // Spring'e "Bu servisi kullanacağım, lütfen hazırla" demek
    private kullaniciservice service;

    @Autowired
    private loginservice loginService;

    @PostMapping("/kaydol") // Adresimiz artık: localhost:8080/kaydol
    public kullanici kaydol(@Valid @RequestBody kaydol request) {  // verileri çekmek için  // requestbody ile çekiyoruz valid ise kontrol ediiyor 
        return service.kullaniciKaydet(request); // Müşteri olarak kaydet
    }
    @PostMapping("/login")
    public String login(@Valid  @RequestBody login login) {
     return loginService.login(login.getEposta(), login.getSifre());

      }
    
}
