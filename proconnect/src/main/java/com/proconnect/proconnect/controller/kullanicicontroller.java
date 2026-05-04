package com.proconnect.proconnect.controller;

import com.proconnect.proconnect.dto.kaydol;
import com.proconnect.proconnect.dto.login;
import com.proconnect.proconnect.entity.Rol;
import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.service.kullaniciservice;
import com.proconnect.proconnect.service.EpostaService;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import com.proconnect.proconnect.service.loginservice;
import com.proconnect.proconnect.repository.kullanicirepository;
import com.proconnect.proconnect.util.jwtutil;

import java.util.LinkedHashMap;
import java.util.Map;


@RestController // Bu sınıfın dış dünyaya kapı olduğunu söyler  // api vb işlemlerini burda yaparız 
@RequestMapping("/") // İŞTE BURASI! Başına hiçbir şey (api/v1 gibi) yazmadık.
public class kullanicicontroller {

    @Autowired // Spring'e "Bu servisi kullanacağım, lütfen hazırla" demek
    private kullaniciservice service;

    @Autowired
    private loginservice loginService;

    @Autowired
    private kullanicirepository kullaniciRepository;

    @Autowired
    private jwtutil jwtUtil;

    @Autowired
    private EpostaService epostaService;

    @PostMapping("/kaydol") // Adresimiz artık: localhost:8080/kaydol
    public kullanici kaydol(@Valid @RequestBody kaydol request) {  // verileri çekmek için  // requestbody ile çekiyoruz valid ise kontrol ediiyor 
        return service.kullaniciKaydet(request); // Müşteri olarak kaydet
    }
    @PostMapping("/login")
    public String login(@Valid @RequestBody login login, HttpServletResponse response) {
        String token = loginService.login(login.getEposta(), login.getSifre());

        Cookie cookie = new Cookie("jwt", token);
        cookie.setHttpOnly(true);   // JS erişemez
        cookie.setSecure(false);    // localhost için false, production'da true yapılacak
        cookie.setPath("/");        // tüm site için geçerli
        cookie.setMaxAge(3600);     // 1 saat
        response.addCookie(cookie);

        return "Giriş başarılı";
      }

    @PostMapping("/cikis")
    public String cikis(HttpServletResponse response) {
        Cookie cookie = new Cookie("jwt", "");
        cookie.setHttpOnly(true);
        cookie.setPath("/");
        cookie.setMaxAge(0); // Cookie'yi sil
        response.addCookie(cookie);
        return "Çıkış yapıldı";
    }

    @GetMapping("/me")
    public Map<String, Object> me(@CookieValue(value = "jwt", required = false) String token) {
        Map<String, Object> sonuc = new LinkedHashMap<>();

        if (token == null || jwtUtil.isTokenExpired(token)) {
            sonuc.put("girisYapildi", false);
            return sonuc;
        }

        String eposta = jwtUtil.extractUsername(token);
        kullanici k = kullaniciRepository.findByEposta(eposta).orElse(null);

        if (k == null) {
            sonuc.put("girisYapildi", false);
            return sonuc;
        }

        sonuc.put("girisYapildi", true);
        sonuc.put("ad", k.getAd());
        sonuc.put("soyad", k.getSoyad());
        sonuc.put("eposta", k.getEposta());
        sonuc.put("rol", k.getRol().name());
        sonuc.put("epostaDogrulandi", k.isEpostaDogrulandi());
        if (k.getRol() == Rol.USTA) {
            sonuc.put("belgeYuklendi", k.getBelgeYolu() != null && !k.getBelgeYolu().isBlank());
        }
        return sonuc;
    }

    @PostMapping("/eposta-dogrula")
    public Map<String, Object> epostaDogrula(@RequestBody Map<String, String> body) {
        String eposta = body.get("eposta");
        String kod = body.get("kod");
        epostaService.koduDogrula(eposta, kod);

        Map<String, Object> sonuc = new LinkedHashMap<>();
        sonuc.put("basarili", true);
        sonuc.put("mesaj", "E-posta basariyla dogrulandi");

        // USTA ise belge yukleme gerektigini bildir
        kullanici k = kullaniciRepository.findByEposta(eposta).orElse(null);
        if (k != null && k.getRol() == Rol.USTA) {
            sonuc.put("belgeYuklemeGerekli", true);
        }
        return sonuc;
    }

    @PostMapping("/kod-tekrar-gonder")
    public Map<String, String> kodTekrarGonder(@RequestBody Map<String, String> body) {
        String eposta = body.get("eposta");
        epostaService.kodTekrarGonder(eposta);

        Map<String, String> sonuc = new LinkedHashMap<>();
        sonuc.put("mesaj", "Dogrulama kodu tekrar gonderildi");
        return sonuc;
    }

}
