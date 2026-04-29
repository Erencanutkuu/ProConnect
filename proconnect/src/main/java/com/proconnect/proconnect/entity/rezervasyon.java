package com.proconnect.proconnect.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "rezervasyonlar")
@Data
public class rezervasyon {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "musteri_id")
    private kullanici musteri;

    @ManyToOne
    @JoinColumn(name = "ilan_id")
    private ilanlar ilan;

    @Enumerated(EnumType.STRING)
    private RezervasyonDurum durum;

    private LocalDateTime rezervasyonTarihi;
    private LocalDateTime tamamlanmaTarihi;

    @PrePersist
    protected void onCreate() {
        rezervasyonTarihi = LocalDateTime.now();
        durum = RezervasyonDurum.BEKLEMEDE;
    }
}
