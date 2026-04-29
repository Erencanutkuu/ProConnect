package com.proconnect.proconnect.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "yorumlar")
@Data
public class yorum {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "musteri_id")
    private kullanici musteri;

    @ManyToOne
    @JoinColumn(name = "ilan_id")
    private ilanlar ilan;

    @Min(1)
    @Max(5)
    private Integer puan;

    @Column(length = 1000)
    private String yorumMetni;

    private LocalDateTime yorumTarihi;

    @PrePersist
    protected void onCreate() {
        yorumTarihi = LocalDateTime.now();
    }
}
