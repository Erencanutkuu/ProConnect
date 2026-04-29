package com.proconnect.proconnect.repository;

import com.proconnect.proconnect.entity.RezervasyonDurum;
import com.proconnect.proconnect.entity.rezervasyon;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface rezervasyonrepository extends JpaRepository<rezervasyon, Long> {
    List<rezervasyon> findByMusteriId(Long musteriId);
    List<rezervasyon> findByIlanId(Long ilanId);
    List<rezervasyon> findByIlanOlusturanKullaniciId(Long ustaId);
    List<rezervasyon> findByDurum(RezervasyonDurum durum);
    boolean existsByMusteriIdAndIlanId(Long musteriId, Long ilanId);
    boolean existsByMusteriIdAndIlanIdAndDurumNot(Long musteriId, Long ilanId, RezervasyonDurum durum);
}
