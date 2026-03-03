package com.proconnect.proconnect.entity;

import jakarta.persistence.*; // Veritabanı bağlantısı için şart
import lombok.Data; // Getter/Setter yorgunluğundan kurtarır
import java.time.LocalDateTime;

import com.proconnect.util.tcno;

@Entity // 1. Bu sınıfın bir tablo olduğunu söyle
@Table(name = "kullanicilar") // 2. Tablo adını belirle
@Data 
public class kullanici {

    @Id // 3. Bu alanın 'Primary Key' (Anahtar) olduğunu belirt
    @GeneratedValue(strategy = GenerationType.IDENTITY) // 4. ID'yi otomatik artır (1, 2, 3...)
    private Long id;

    private String ad;
    private String soyad;
    private String eposta;
    private String sifreHash;
    
    @Enumerated(EnumType.STRING) // 5. İŞTE O KRİTİK SATIR! Rolü veritabanına metin olarak yaz
    private Rol rol;

    @Embedded
    private tcno tcno;

    private LocalDateTime olusturulmaTarihi;

    @PrePersist // 6. Kayıt anında saati otomatik damgala
    protected void onCreate() {
        olusturulmaTarihi = LocalDateTime.now();
    }
}