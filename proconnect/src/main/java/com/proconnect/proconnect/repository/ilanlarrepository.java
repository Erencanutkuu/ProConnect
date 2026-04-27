package com.proconnect.proconnect.repository;

import com.proconnect.proconnect.entity.ilanlar;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ilanlarrepository extends JpaRepository<ilanlar, Long> {

    @Query("SELECT i FROM ilanlar i WHERE i.durum = 'ACIK' AND " +
           "(LOWER(i.baslik) LIKE LOWER(CONCAT('%', :arama, '%')) OR " +
           "LOWER(i.aciklama) LIKE LOWER(CONCAT('%', :arama, '%')))")
    List<ilanlar> aramaYap(@Param("arama") String arama);

    @Query("SELECT i FROM ilanlar i WHERE i.durum = 'ACIK' AND " +
           "(LOWER(i.baslik) LIKE LOWER(CONCAT('%', :arama, '%')) OR " +
           "LOWER(i.aciklama) LIKE LOWER(CONCAT('%', :arama, '%'))) AND " +
           "LOWER(i.sehir) LIKE LOWER(CONCAT('%', :sehir, '%'))")
    List<ilanlar> aramaSehirIle(@Param("arama") String arama, @Param("sehir") String sehir);
}
