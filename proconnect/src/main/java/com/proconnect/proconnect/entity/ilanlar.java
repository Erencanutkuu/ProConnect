package com.proconnect.proconnect.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "ilanlar")
@Data
public class ilanlar {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String baslik;

    @Column(length = 2000)
    private String aciklama;

    private BigDecimal butce;

    @Enumerated(EnumType.STRING)
    private Durum durum;

    private Double konumLat;
    private Double konumLng;
    private String sehir;
    private String ilce;

    private LocalDateTime ilanTarihi;
    private String gorselYolu;

    // İlanı oluşturan kişi (sadece USTA olmalı - iş kuralı servis katmanında)
    @ManyToOne
    @JoinColumn(name = "olusturan_kullanici_id")
    private kullanici olusturanKullanici;

    // İlanı açan kişi
    @ManyToOne
    @JoinColumn(name = "acilan_kullanici_id")
    private kullanici acilanKullanici;

    @PrePersist
    protected void onCreate() {
        if (durum == null) durum = Durum.ACIK;
        if (ilanTarihi == null) ilanTarihi = LocalDateTime.now();
    }
}
