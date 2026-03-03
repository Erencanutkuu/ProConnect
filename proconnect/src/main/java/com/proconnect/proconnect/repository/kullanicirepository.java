package com.proconnect.proconnect.repository;

import com.proconnect.proconnect.entity.kullanici;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface kullanicirepository extends JpaRepository<kullanici, Long> {
    // Eposta ile kullanıcı aramak için özel bir yöntem
    boolean existsByEposta(String eposta);
}