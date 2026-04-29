package com.proconnect.proconnect.repository;

import com.proconnect.proconnect.entity.yorum;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface yorumrepository extends JpaRepository<yorum, Long> {
    List<yorum> findByIlanId(Long ilanId);
    List<yorum> findByMusteriId(Long musteriId);
    long countByIlanId(Long ilanId);
    boolean existsByMusteriIdAndIlanId(Long musteriId, Long ilanId);

    @Query("SELECT AVG(y.puan) FROM yorum y WHERE y.ilan.id = :ilanId")
    Double ortalamaByIlanId(@Param("ilanId") Long ilanId);

    @Query("SELECT AVG(y.puan) FROM yorum y WHERE y.ilan.olusturanKullanici.id = :ustaId")
    Double ortalamaByUstaId(@Param("ustaId") Long ustaId);
}
