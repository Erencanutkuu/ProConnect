package com.proconnect.proconnect.repository;

import com.proconnect.proconnect.entity.cerezler;
import com.proconnect.proconnect.entity.kullanici;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface cerezlerrepository extends JpaRepository<cerezler, Long> {
    Optional<cerezler> findByKullanici(kullanici kullanici);
}
