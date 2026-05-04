package com.proconnect.proconnect.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "mesajlar")
@Data
public class mesaj {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "gonderen_id", nullable = false)
    private kullanici gonderen;

    @ManyToOne
    @JoinColumn(name = "alici_id", nullable = false)
    private kullanici alici;

    @ManyToOne
    @JoinColumn(name = "ilan_id")
    private ilanlar ilan;

    @Column(length = 2000, nullable = false)
    private String mesajMetni;

    private LocalDateTime tarih;

    private Boolean okundu = false;

    @PrePersist
    protected void onCreate() {
        if (tarih == null) tarih = LocalDateTime.now();
    }
}
