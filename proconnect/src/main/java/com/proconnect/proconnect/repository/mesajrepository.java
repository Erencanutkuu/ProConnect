package com.proconnect.proconnect.repository;

import com.proconnect.proconnect.entity.mesaj;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.data.domain.Pageable;

import java.util.List;

@Repository
public interface mesajrepository extends JpaRepository<mesaj, Long> {

    // İki kullanıcı arasındaki mesajlar (tarih sırasıyla)
    @Query("SELECT m FROM mesaj m WHERE " +
           "(m.gonderen.id = :id1 AND m.alici.id = :id2) OR " +
           "(m.gonderen.id = :id2 AND m.alici.id = :id1) " +
           "ORDER BY m.tarih ASC")
    List<mesaj> mesajlarArasinda(@Param("id1") Long id1, @Param("id2") Long id2);

    // Kullanıcının konuşma yaptığı partner ID'leri
    @Query("SELECT DISTINCT CASE WHEN m.gonderen.id = :userId THEN m.alici.id ELSE m.gonderen.id END " +
           "FROM mesaj m WHERE m.gonderen.id = :userId OR m.alici.id = :userId")
    List<Long> konusmaPartnerleri(@Param("userId") Long userId);

    // Bir kullanıcıdan gelen okunmamış mesaj sayısı
    @Query("SELECT COUNT(m) FROM mesaj m WHERE m.alici.id = :aliciId AND m.gonderen.id = :gonderenId AND m.okundu = false")
    long okunmamisSayisiPartner(@Param("aliciId") Long aliciId, @Param("gonderenId") Long gonderenId);

    // Toplam okunmamış mesaj sayısı
    @Query("SELECT COUNT(m) FROM mesaj m WHERE m.alici.id = :aliciId AND m.okundu = false")
    long toplamOkunmamis(@Param("aliciId") Long aliciId);

    // Mesajları okundu işaretle
    @Modifying
    @Transactional
    @Query("UPDATE mesaj m SET m.okundu = true WHERE m.alici.id = :aliciId AND m.gonderen.id = :gonderenId AND m.okundu = false")
    void okunduIsaretle(@Param("aliciId") Long aliciId, @Param("gonderenId") Long gonderenId);

    // İki kullanıcı arasındaki son mesajlar (tarih azalan)
    @Query("SELECT m FROM mesaj m WHERE " +
           "(m.gonderen.id = :id1 AND m.alici.id = :id2) OR " +
           "(m.gonderen.id = :id2 AND m.alici.id = :id1) " +
           "ORDER BY m.tarih DESC")
    List<mesaj> sonMesajlar(@Param("id1") Long id1, @Param("id2") Long id2, Pageable pageable);
}
