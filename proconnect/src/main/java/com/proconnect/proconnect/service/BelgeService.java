package com.proconnect.proconnect.service;

import com.proconnect.proconnect.entity.Rol;
import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.repository.kullanicirepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Set;

@Service
public class BelgeService {

    @Value("${belge.upload.dir}")
    private String uploadDir;

    @Autowired
    private kullanicirepository kullaniciRepository;

    private static final Set<String> IZIN_VERILEN_TIPLER = Set.of(
            "application/pdf", "image/jpeg", "image/png"
    );

    public String belgeYukle(String eposta, MultipartFile dosya) {
        kullanici k = kullaniciRepository.findByEposta(eposta)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanici bulunamadi"));

        if (k.getRol() != Rol.USTA) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Sadece ustalar belge yukleyebilir");
        }

        if (!Boolean.TRUE.equals(k.getEpostaDogrulandi())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Once e-postanizi dogrulayin");
        }

        if (dosya.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Dosya bos");
        }

        String contentType = dosya.getContentType();
        if (contentType == null || !IZIN_VERILEN_TIPLER.contains(contentType)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Sadece PDF, JPG ve PNG dosyalari kabul edilir");
        }

        try {
            Path kullaniciDizin = Paths.get(uploadDir, k.getId().toString());
            Files.createDirectories(kullaniciDizin);

            String orijinalAd = dosya.getOriginalFilename();
            String uzanti = "";
            if (orijinalAd != null && orijinalAd.contains(".")) {
                uzanti = orijinalAd.substring(orijinalAd.lastIndexOf("."));
            }
            String dosyaAdi = "belge_" + System.currentTimeMillis() + uzanti;

            Path hedefYol = kullaniciDizin.resolve(dosyaAdi);
            Files.copy(dosya.getInputStream(), hedefYol, StandardCopyOption.REPLACE_EXISTING);

            k.setBelgeYolu(hedefYol.toString());
            kullaniciRepository.save(k);

            return hedefYol.toString();

        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Dosya yuklenirken hata olustu");
        }
    }
}
