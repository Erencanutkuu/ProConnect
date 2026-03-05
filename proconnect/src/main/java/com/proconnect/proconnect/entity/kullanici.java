package com.proconnect.proconnect.entity;

import jakarta.persistence.*; // Veritabanı bağlantısı için şart
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
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
     
    @NotBlank(message = "E-posta boş bırakılamaz") // 7. E-posta boş olamaz
    @Email(message = "Geçersiz e-posta formatı")
    @Column(unique = true)
    private String eposta;

    @NotBlank(message = "Ad boş bırakılamaz") // 8. Ad boş olamaz
    private String ad;

    @NotBlank(message = "Soyad boş bırakılamaz") // 9. Soyad boş olamaz
    private String soyad;

    @NotBlank(message = "Şifre boş bırakılamaz") // 10. Şifre boş olamaz
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