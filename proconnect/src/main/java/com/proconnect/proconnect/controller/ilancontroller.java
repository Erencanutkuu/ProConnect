package com.proconnect.proconnect.controller;

import com.proconnect.proconnect.entity.ilanlar;
import com.proconnect.proconnect.service.GorselService;
import com.proconnect.proconnect.service.ilanservice;
import com.proconnect.proconnect.util.jwtutil;
import com.proconnect.proconnect.util.JwtResolver;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.LinkedHashMap;
import java.util.Map;

import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/ilan")
public class ilancontroller {

    @Autowired
    private ilanservice ilanService;

    @Autowired
    private jwtutil jwtUtil;

    @Autowired
    private GorselService gorselService;

    @PostMapping(value = "/olustur", consumes = {"multipart/form-data"})
    public ilanlar olustur(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request,
            @RequestParam("baslik") String baslik,
            @RequestParam("aciklama") String aciklama,
            @RequestParam(value = "butce", required = false) BigDecimal butce,
            @RequestParam(value = "sehir", required = false) String sehir,
            @RequestParam(value = "ilce", required = false) String ilce,
            @RequestParam(value = "konumLat", required = false) Double konumLat,
            @RequestParam(value = "konumLng", required = false) Double konumLng,
            @RequestParam(value = "gorsel", required = false) MultipartFile gorsel) {

        String token = cookieToken != null ? cookieToken : JwtResolver.resolveToken(request);
        String eposta = jwtUtil.extractUsername(token);
        String gorselYolu = null;

        if (gorsel != null && !gorsel.isEmpty()) {
            try {
                // Resmi statik klasörüne kaydet
                String uploadsDir = "src/main/resources/static/uploads/";
                Path uploadPath = Paths.get(uploadsDir);
                if (!Files.exists(uploadPath)) {
                    Files.createDirectories(uploadPath);
                }
                String originalFilename = gorsel.getOriginalFilename();
                String extension = "";
                if (originalFilename != null && originalFilename.contains(".")) {
                    extension = originalFilename.substring(originalFilename.lastIndexOf("."));
                }
                String fileName = UUID.randomUUID().toString() + extension;
                Path filePath = uploadPath.resolve(fileName);
                Files.copy(gorsel.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
                gorselYolu = fileName;
            } catch (Exception e) {
                // Hata durumunda yoksay veya logla, ilan resimsiz oluşsun
            }
        }

        // Gorsel yuklenmemisse AI ile uret
        if (gorselYolu == null) {
            gorselYolu = gorselService.gorselUret(baslik, aciklama);
        }

        return ilanService.olustur(
            eposta,
            baslik,
            aciklama,
            butce,
            sehir,
            ilce,
            konumLat,
            konumLng,
            gorselYolu
        );
    }

    @GetMapping("/aktif")
    public List<ilanlar> aktifIlanlar(
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng,
            @RequestParam(required = false) String sehir) {
        return ilanService.aktifIlanlar(lat, lng, sehir);
    }

    @GetMapping("/benimkiler")
    public List<ilanlar> benimkiler(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request) {
        String token = cookieToken != null ? cookieToken : JwtResolver.resolveToken(request);
        String eposta = jwtUtil.extractUsername(token);
        return ilanService.benimIlanlarim(eposta);
    }

    @DeleteMapping("/sil/{id}")
    public Map<String, String> ilanSil(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request,
            @PathVariable("id") Long id) {
        String token = cookieToken != null ? cookieToken : JwtResolver.resolveToken(request);
        String eposta = jwtUtil.extractUsername(token);
        ilanService.ilanSil(eposta, id);
        return Map.of("mesaj", "İlan silindi");
    }

    @PutMapping("/guncelle/{id}")
    public Map<String, Object> ilanGuncelle(
            @CookieValue(value = "jwt", required = false) String cookieToken,
            HttpServletRequest request,
            @PathVariable("id") Long id,
            @RequestBody Map<String, Object> body) {
        String token = cookieToken != null ? cookieToken : JwtResolver.resolveToken(request);
        String eposta = jwtUtil.extractUsername(token);

        String baslik = (String) body.get("baslik");
        String aciklama = (String) body.get("aciklama");
        BigDecimal butce = body.get("butce") != null ? new BigDecimal(body.get("butce").toString()) : null;
        String sehir = (String) body.get("sehir");
        String ilce = (String) body.get("ilce");

        ilanService.ilanGuncelle(eposta, id, baslik, aciklama, butce, sehir, ilce);

        Map<String, Object> sonuc = new LinkedHashMap<>();
        sonuc.put("basarili", true);
        sonuc.put("mesaj", "İlan güncellendi");
        return sonuc;
    }
}
