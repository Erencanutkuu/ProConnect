package com.proconnect.proconnect.service;

import com.proconnect.proconnect.entity.kullanici;
import com.proconnect.proconnect.repository.kullanicirepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.Random;

@Service
public class EpostaService {

    @Autowired
    private JavaMailSender mailSender;

    @Autowired
    private kullanicirepository kullaniciRepository;

    private final Random random = new Random();

    public void dogrulamaKoduGonder(kullanici kullanici) {
        String kod = String.format("%06d", random.nextInt(1000000));

        kullanici.setEpostaDogrulamaKodu(kod);
        kullanici.setKodGonderimZamani(LocalDateTime.now());
        kullaniciRepository.save(kullanici);

        SimpleMailMessage mesaj = new SimpleMailMessage();
        mesaj.setTo(kullanici.getEposta());
        mesaj.setSubject("ProConnect - E-posta Dogrulama Kodu");
        mesaj.setText("Merhaba " + kullanici.getAd() + ",\n\n"
                + "E-posta dogrulama kodunuz: " + kod + "\n\n"
                + "Bu kod 10 dakika gecerlidir.\n\n"
                + "ProConnect");

        mailSender.send(mesaj);
    }

    public void koduDogrula(String eposta, String kod) {
        kullanici k = kullaniciRepository.findByEposta(eposta)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanici bulunamadi"));

        if (k.isEpostaDogrulandi()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "E-posta zaten dogrulandi");
        }

        if (k.getEpostaDogrulamaKodu() == null || k.getKodGonderimZamani() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Dogrulama kodu bulunamadi");
        }

        if (k.getKodGonderimZamani().plusMinutes(10).isBefore(LocalDateTime.now())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Dogrulama kodunun suresi dolmus");
        }

        if (!k.getEpostaDogrulamaKodu().equals(kod)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Dogrulama kodu hatali");
        }

        k.setEpostaDogrulandi(true);
        k.setEpostaDogrulamaKodu(null);
        k.setKodGonderimZamani(null);
        kullaniciRepository.save(k);
    }

    public void kodTekrarGonder(String eposta) {
        kullanici k = kullaniciRepository.findByEposta(eposta)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanici bulunamadi"));

        if (k.isEpostaDogrulandi()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "E-posta zaten dogrulandi");
        }

        dogrulamaKoduGonder(k);
    }
}
