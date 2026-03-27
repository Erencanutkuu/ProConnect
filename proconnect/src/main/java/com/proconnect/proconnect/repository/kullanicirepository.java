package com.proconnect.proconnect.repository;

import com.proconnect.proconnect.entity.kullanici;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository    // gerçek db ye erişen kısım burası sadece bu kullanıcı db sine erişir ve işlemler yapar
public interface kullanicirepository extends JpaRepository<kullanici, Long> {
    // Eposta ile kullanıcı aramak için özel bir yöntem
    boolean existsByEposta(String eposta);   // eposta var mı yok mu kontrol eder
    Optional<kullanici> findByEposta(String eposta);
}