package com.proconnect.proconnect.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "cerezler")
@Data
public class cerezler {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "kullanici_id")
    private kullanici kullanici;

    private Boolean cerezOnay;
    private Boolean konumIzni;
    private Double konumLat;
    private Double konumLng;

    private LocalDateTime cerezTarihi;
    private LocalDateTime konumGuncellenme;
}
